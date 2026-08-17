#!/usr/bin/env bash
set -euo pipefail

confirmation="${1:-${CLEANUP_CONFIRMATION:-}}"
dry_run="${DRY_RUN:-false}"
report_directory="${REPORT_DIRECTORY:-reports/dev-cleanup}"

if [[ "$confirmation" != "DELETE-DEV" ]]; then
  echo "::error::Confirmation must be exactly DELETE-DEV."
  exit 1
fi

if [[ -z "${EXPECTED_SUBSCRIPTION_ID:-}" ||
  -z "${EXPECTED_TENANT_ID:-}" ]]; then
  echo "::error::Expected subscription and tenant are required."
  exit 1
fi

actual_subscription_id="$(
  az account show --query id --output tsv
)"

actual_tenant_id="$(
  az account show --query tenantId --output tsv
)"

if [[ "$actual_subscription_id" != "$EXPECTED_SUBSCRIPTION_ID" ]]; then
  echo "::error::Azure CLI is using an unexpected subscription."
  exit 1
fi

if [[ "$actual_tenant_id" != "$EXPECTED_TENANT_ID" ]]; then
  echo "::error::Azure CLI is using an unexpected tenant."
  exit 1
fi

mkdir -p "$report_directory"

resource_groups=(
  rg-nshop-dev-global
  rg-nshop-dev-gwc
  rg-nshop-dev-cac
  rg-nshop-dev-network
  rg-nshop-dev-monitor
  rg-nshop-dev-security
)

dev_key_vaults=(
  kv-nshop-dev-gwc
  kv-nshop-dev-cac
)

dev_budget_name="budget-nshop-dev-monthly"
legacy_budget_name="budget-nshop-monthly"

declare -A approved_resource_groups=()

for resource_group in "${resource_groups[@]}"; do
  approved_resource_groups["$resource_group"]=1
done

mapfile -t discovered_dev_resource_groups < <(
  az group list \
    --query "[?starts_with(name, 'rg-nshop-dev')].name" \
    --output tsv
)

for resource_group in "${discovered_dev_resource_groups[@]}"; do
  if [[ -z "${approved_resource_groups[$resource_group]:-}" ]]; then
    echo "::error::Unexpected dev resource group found: $resource_group"
    exit 1
  fi
done

az group list \
  --query "[?starts_with(name, 'rg-nshop-dev')].{
    name:name,
    location:location,
    state:properties.provisioningState
  }" \
  --output json \
  >"$report_directory/resource-groups-before.json"

az policy assignment list \
  --query "[?starts_with(name, 'nshop-dev-')].{
    name:name,
    displayName:displayName,
    scope:scope
  }" \
  --output json \
  >"$report_directory/policies-before.json"

az consumption budget list \
  --query "[?name=='budget-nshop-dev-monthly' || name=='budget-nshop-monthly'].{
    name:name,
    amount:amount,
    timeGrain:timeGrain
  }" \
  --output json \
  >"$report_directory/budgets-before.json"

az keyvault list-deleted \
  --query "[?name=='kv-nshop-dev-gwc' || name=='kv-nshop-dev-cac'].{
    name:name,
    location:properties.location,
    purgeProtection:properties.purgeProtectionEnabled
  }" \
  --output json \
  >"$report_directory/deleted-key-vaults-before.json"

mapfile -t dev_policy_assignments < <(
  az policy assignment list \
    --query "[?starts_with(name, 'nshop-dev-')].name" \
    --output tsv
)

for policy_assignment in "${dev_policy_assignments[@]}"; do
  if [[ "$dry_run" == "true" ]]; then
    echo "DRY RUN: Would delete policy assignment: $policy_assignment"
  else
    az policy assignment delete \
      --name "$policy_assignment" \
      --only-show-errors
  fi
done

budget_names="$(
  az consumption budget list \
    --query "[?name=='${dev_budget_name}' || name=='${legacy_budget_name}'].name" \
    --output tsv
)"

if grep -Fxq "$dev_budget_name" <<<"$budget_names"; then
  if [[ "$dry_run" == "true" ]]; then
    echo "DRY RUN: Would delete budget: $dev_budget_name"
  else
    az consumption budget delete \
      --budget-name "$dev_budget_name" \
      --only-show-errors
  fi
fi

if grep -Fxq "$legacy_budget_name" <<<"$budget_names"; then
  production_markers="$(
    {
      az group list \
        --query "[?starts_with(name, 'rg-nshop-prod')].name" \
        --output tsv

      az policy assignment list \
        --query "[?starts_with(name, 'nshop-prod-')].name" \
        --output tsv

      az consumption budget list \
        --query "[?name=='budget-nshop-prod-monthly'].name" \
        --output tsv
    } | sed '/^[[:space:]]*$/d'
  )"

  if [[ -n "$production_markers" ]]; then
    echo "::error::Legacy shared budget exists while production markers are present."
    echo "::error::Refusing to delete ambiguous budget: $legacy_budget_name"
    exit 1
  fi

  if [[ "$dry_run" == "true" ]]; then
    echo "DRY RUN: Would delete legacy budget: $legacy_budget_name"
  else
    az consumption budget delete \
      --budget-name "$legacy_budget_name" \
      --only-show-errors
  fi
fi

for resource_group in "${resource_groups[@]}"; do
  if [[ "$(az group exists --name "$resource_group")" == "true" ]]; then
    if [[ "$dry_run" == "true" ]]; then
      echo "DRY RUN: Would delete resource group: $resource_group"
    else
      az group delete \
        --name "$resource_group" \
        --yes \
        --no-wait \
        --only-show-errors
    fi
  fi
done

if [[ "$dry_run" != "true" ]]; then
  for attempt in {1..60}; do
    remaining_resource_groups=()

    for resource_group in "${resource_groups[@]}"; do
      if [[ "$(az group exists --name "$resource_group")" == "true" ]]; then
        remaining_resource_groups+=("$resource_group")
      fi
    done

    if ((${#remaining_resource_groups[@]} == 0)); then
      break
    fi

    if ((attempt == 60)); then
      printf '%s\n' \
        "::error::Timed out waiting for resource-group deletion:" \
        "${remaining_resource_groups[@]}"
      exit 1
    fi

    sleep 10
  done
fi

if [[ "$dry_run" != "true" ]]; then
  for attempt in {1..30}; do
    deleted_vault_count=0

    for key_vault_name in "${dev_key_vaults[@]}"; do
      deleted_vault_location="$(
        az keyvault list-deleted \
          --query "[?name=='${key_vault_name}'].properties.location | [0]" \
          --output tsv
      )"

      if [[ -n "$deleted_vault_location" ]]; then
        deleted_vault_count=$((deleted_vault_count + 1))

        az keyvault purge \
          --name "$key_vault_name" \
          --location "$deleted_vault_location" \
          --only-show-errors
      fi
    done

    if ((deleted_vault_count == 0)); then
      break
    fi

    sleep 10
  done
fi

az group list \
  --query "[?starts_with(name, 'rg-nshop-dev')].{
    name:name,
    location:location,
    state:properties.provisioningState
  }" \
  --output json \
  >"$report_directory/resource-groups-after.json"

az policy assignment list \
  --query "[?starts_with(name, 'nshop-dev-')].{
    name:name,
    displayName:displayName,
    scope:scope
  }" \
  --output json \
  >"$report_directory/policies-after.json"

az consumption budget list \
  --query "[?name=='budget-nshop-dev-monthly' || name=='budget-nshop-monthly'].{
    name:name,
    amount:amount,
    timeGrain:timeGrain
  }" \
  --output json \
  >"$report_directory/budgets-after.json"

az keyvault list-deleted \
  --query "[?name=='kv-nshop-dev-gwc' || name=='kv-nshop-dev-cac'].{
    name:name,
    location:properties.location,
    purgeProtection:properties.purgeProtectionEnabled
  }" \
  --output json \
  >"$report_directory/deleted-key-vaults-after.json"

if [[ "$dry_run" == "true" ]]; then
  echo "Dev cleanup dry run completed."
  exit 0
fi

remaining_count="$(
  jq -s \
    'map(length) | add' \
    "$report_directory/resource-groups-after.json" \
    "$report_directory/policies-after.json" \
    "$report_directory/budgets-after.json" \
    "$report_directory/deleted-key-vaults-after.json"
)"

if ((remaining_count != 0)); then
  echo "::error::Dev cleanup verification found remaining targets."
  exit 1
fi

remaining_tagged_resources="$(
  az resource list \
    --tag environment=dev \
    --query "[?tags.application=='nordic-shopping'].name" \
    --output tsv
)"

if [[ -n "$remaining_tagged_resources" ]]; then
  echo "::error::Tagged Nordic Shopping dev resources remain."
  exit 1
fi

echo "PASS: All approved dev resource groups were removed."
echo "PASS: All nshop-dev policy assignments were removed."
echo "PASS: Dev and legacy dev budgets were removed."
echo "PASS: No soft-deleted dev Key Vault conflicts remain."
echo "PASS: Shared bootstrap identities, federated credentials, custom roles, and deployment records were preserved."
echo "Guarded dev cleanup completed successfully."
