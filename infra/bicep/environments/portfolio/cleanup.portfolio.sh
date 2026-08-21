#!/usr/bin/env bash
set -euo pipefail

confirmation="${1:-${PORTFOLIO_CLEANUP_CONFIRMATION:-}}"
dry_run="${PORTFOLIO_DRY_RUN:-false}"
report_directory="${PORTFOLIO_REPORT_DIRECTORY:-reports/portfolio-cleanup}"

if [[ "$confirmation" != 'DELETE-PORTFOLIO' ]]; then
  echo '::error::Confirmation must be exactly DELETE-PORTFOLIO.'
  exit 1
fi

required_variables=(
  EXPECTED_SUBSCRIPTION_ID
  EXPECTED_TENANT_ID
  PORTFOLIO_PRIMARY_REGION_CODE
  PORTFOLIO_SECONDARY_REGION_CODE
)

for variable_name in "${required_variables[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "::error::Required environment variable is missing: $variable_name"
    exit 1
  fi
done

if [[ "$(az account show --query id --output tsv)" != "$EXPECTED_SUBSCRIPTION_ID" ||
  "$(az account show --query tenantId --output tsv)" != "$EXPECTED_TENANT_ID" ]]; then
  echo '::error::Azure CLI is using an unexpected subscription or tenant.'
  exit 1
fi

mkdir -p "$report_directory"

approved_groups=(
  rg-nshop-dev-global
  "rg-nshop-dev-${PORTFOLIO_PRIMARY_REGION_CODE}"
  "rg-nshop-dev-${PORTFOLIO_SECONDARY_REGION_CODE}"
  rg-nshop-dev-network
  rg-nshop-dev-monitor
  rg-nshop-dev-security
)

declare -A allowed_groups=()
for resource_group in "${approved_groups[@]}"; do
  allowed_groups["$resource_group"]=1
done

mapfile -t discovered_groups < <(
  az group list --query "[?starts_with(name, 'rg-nshop-dev')].name" --output tsv
)

for resource_group in "${discovered_groups[@]}"; do
  if [[ -z "${allowed_groups[$resource_group]:-}" ]]; then
    echo "::error::Unexpected Nordic Shopping development resource group: $resource_group"
    exit 1
  fi
done

az group list \
  --query "[?starts_with(name, 'rg-nshop-dev')].{name:name,location:location,state:properties.provisioningState}" \
  --output json >"$report_directory/resource-groups-before.portfolio.json"

mapfile -t policy_assignments < <(
  az policy assignment list --query "[?starts_with(name, 'nshop-dev-')].name" --output tsv
)

for assignment in "${policy_assignments[@]}"; do
  if [[ "$dry_run" == 'true' ]]; then
    echo "DRY RUN: Would delete policy assignment: $assignment"
  else
    az policy assignment delete --name "$assignment" --only-show-errors
  fi
done

for budget_name in budget-nshop-dev-monthly budget-nshop-monthly; do
  if [[ -z "$(az consumption budget list --query "[?name=='${budget_name}'].name" --output tsv)" ]]; then
    continue
  fi

  if [[ "$budget_name" == 'budget-nshop-monthly' ]]; then
    production_markers="$(
      {
        az group list --query "[?starts_with(name, 'rg-nshop-prod')].name" --output tsv
        az policy assignment list --query "[?starts_with(name, 'nshop-prod-')].name" --output tsv
        az consumption budget list --query "[?name=='budget-nshop-prod-monthly'].name" --output tsv
      } | sed '/^[[:space:]]*$/d'
    )"

    if [[ -n "$production_markers" ]]; then
      echo '::error::Refusing to delete an ambiguous shared budget while production resources exist.'
      exit 1
    fi
  fi

  if [[ "$dry_run" == 'true' ]]; then
    echo "DRY RUN: Would delete budget: $budget_name"
  else
    az consumption budget delete --budget-name "$budget_name" --only-show-errors
  fi
done

for resource_group in "${approved_groups[@]}"; do
  if [[ "$(az group exists --name "$resource_group")" != 'true' ]]; then
    continue
  fi

  if [[ "$dry_run" == 'true' ]]; then
    echo "DRY RUN: Would delete resource group: $resource_group"
  else
    az group delete --name "$resource_group" --yes --no-wait --only-show-errors
  fi
done

if [[ "$dry_run" == 'true' ]]; then
  echo 'PASS: Portfolio cleanup dry run completed without changing Azure resources.'
  exit 0
fi

for attempt in {1..60}; do
  remaining="$(az group list --query "[?starts_with(name, 'rg-nshop-dev')].name" --output tsv)"
  if [[ -z "$remaining" ]]; then
    break
  fi

  if ((attempt == 60)); then
    echo '::error::Timed out waiting for portfolio resource groups to be deleted.'
    exit 1
  fi

  sleep 10
done

for region_code in "$PORTFOLIO_PRIMARY_REGION_CODE" "$PORTFOLIO_SECONDARY_REGION_CODE"; do
  vault_name="kv-nshop-dev-${region_code}"
  vault_location="$(az keyvault list-deleted --query "[?name=='${vault_name}'].properties.location | [0]" --output tsv)"

  if [[ -n "$vault_location" && "$vault_location" != 'None' ]]; then
    az keyvault purge --name "$vault_name" --location "$vault_location" --only-show-errors
  fi
done

az group list --query "[?starts_with(name, 'rg-nshop-dev')].name" --output json \
  >"$report_directory/resource-groups-after.portfolio.json"

az keyvault list-deleted --query "[?starts_with(name, 'kv-nshop-dev-')].name" --output json \
  >"$report_directory/deleted-key-vaults-after.portfolio.json"

if ! jq -e 'length == 0' "$report_directory/resource-groups-after.portfolio.json" >/dev/null; then
  echo '::error::Portfolio resource groups still exist after cleanup.'
  exit 1
fi

if ! jq -e 'length == 0' "$report_directory/deleted-key-vaults-after.portfolio.json" >/dev/null; then
  echo '::error::Soft-deleted Nordic Shopping development Key Vaults remain after cleanup.'
  exit 1
fi

echo 'PASS: Portfolio resource groups, policies, budget and regional Key Vaults were removed.'
echo 'PASS: Production resources, bootstrap identities and deployment records were not targeted.'
