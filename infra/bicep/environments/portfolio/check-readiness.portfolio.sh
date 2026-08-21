#!/usr/bin/env bash
set -euo pipefail

parameter_file="${1:-infra/bicep/environments/portfolio/main.portfolio.bicepparam}"
report_directory="${PORTFOLIO_REPORT_DIRECTORY:-reports/portfolio}"
mkdir -p "$report_directory"

required_variables=(
  EXPECTED_SUBSCRIPTION_ID
  EXPECTED_TENANT_ID
  DEPLOY_PRINCIPAL_OBJECT_ID
  SQL_ENTRA_ADMIN_OBJECT_ID
  DATABASE_ADMINISTRATORS_GROUP_OBJECT_ID
  PORTFOLIO_PRIMARY_LOCATION
  PORTFOLIO_PRIMARY_REGION_CODE
  PORTFOLIO_SECONDARY_LOCATION
  PORTFOLIO_SECONDARY_REGION_CODE
  PORTFOLIO_APP_SERVICE_SKU
)

for variable_name in "${required_variables[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "::error::Required environment variable is missing: $variable_name"
    exit 1
  fi
done

actual_subscription_id="$(az account show --query id --output tsv)"
actual_tenant_id="$(az account show --query tenantId --output tsv)"

if [[ "$actual_subscription_id" != "$EXPECTED_SUBSCRIPTION_ID" ||
  "$actual_tenant_id" != "$EXPECTED_TENANT_ID" ]]; then
  echo '::error::Azure login resolved to an unexpected subscription or tenant.'
  exit 1
fi

if [[ "$SQL_ENTRA_ADMIN_OBJECT_ID" != "$DATABASE_ADMINISTRATORS_GROUP_OBJECT_ID" ]]; then
  echo '::error::The SQL administrator is not the configured database-administrators group.'
  exit 1
fi

if group_json="$(
  az ad group show \
    --group "$DATABASE_ADMINISTRATORS_GROUP_OBJECT_ID" \
    --output json 2>"$report_directory/sql-administrator-lookup.stderr.txt"
)"; then
  if ! jq -e \
    --arg object_id "$DATABASE_ADMINISTRATORS_GROUP_OBJECT_ID" \
    '.id == $object_id and .securityEnabled == true and (.displayName | length > 0)' \
    <<<"$group_json" >/dev/null; then
    echo '::error::The SQL administrator group is missing or is not security-enabled.'
    exit 1
  fi

  resolved_login="$(jq -r '.displayName' <<<"$group_json")"
  printf '%s\n' "$group_json" | jq '{id, displayName, securityEnabled}' \
    >"$report_directory/sql-administrator.portfolio.json"
  echo 'PASS: SQL administrator object and exact Entra display name were verified.'
else
  if [[ "${PORTFOLIO_ALLOW_UNVERIFIED_SQL_GROUP:-false}" != 'true' ]]; then
    echo '::error::The deployment identity cannot verify the SQL administrator group in Microsoft Entra.'
    echo '::error::Grant directory read access or explicitly accept PORTFOLIO_ALLOW_UNVERIFIED_SQL_GROUP.'
    exit 1
  fi

  resolved_login="${PORTFOLIO_SQL_ADMIN_LOGIN:-}"
  if [[ -z "$resolved_login" ]]; then
    echo '::error::An explicit SQL administrator login is required when directory verification is unavailable.'
    exit 1
  fi

  echo 'WARN: SQL administrator object could not be checked against Microsoft Entra.'
fi

if [[ -n "${PORTFOLIO_SQL_ADMIN_LOGIN:-}" && "$PORTFOLIO_SQL_ADMIN_LOGIN" != "$resolved_login" ]]; then
  echo '::error::The SQL administrator login does not match the current Entra group display name.'
  exit 1
fi

export PORTFOLIO_SQL_ADMIN_LOGIN="$resolved_login"
if [[ -n "${GITHUB_ENV:-}" ]]; then
  printf 'PORTFOLIO_SQL_ADMIN_LOGIN=%s\n' "$resolved_login" >>"$GITHUB_ENV"
fi

required_providers=(
  Microsoft.Resources
  Microsoft.Authorization
  Microsoft.Sql
  Microsoft.Web
  Microsoft.Network
  Microsoft.Storage
  Microsoft.KeyVault
  Microsoft.Insights
  Microsoft.OperationalInsights
  Microsoft.CostManagement
  Microsoft.Cdn
)

for provider in "${required_providers[@]}"; do
  registration_state="$(az provider show --namespace "$provider" --query registrationState --output tsv)"
  if [[ "${registration_state,,}" != 'registered' ]]; then
    echo "::error::Required resource provider is not registered: $provider"
    exit 1
  fi
done

required_roles=(
  Contributor
  'User Access Administrator'
  'Resource Policy Contributor'
  'Cost Management Contributor'
)

assigned_roles="$(
  az role assignment list \
    --all \
    --include-inherited \
    --query "[?principalId=='${DEPLOY_PRINCIPAL_OBJECT_ID}'].roleDefinitionName" \
    --output json
)"

for role in "${required_roles[@]}"; do
  if ! jq -e --arg role "$role" 'index($role) != null' <<<"$assigned_roles" >/dev/null; then
    echo "::error::Deployment identity lacks the required role: $role"
    exit 1
  fi
done

for location in "$PORTFOLIO_PRIMARY_LOCATION" "$PORTFOLIO_SECONDARY_LOCATION"; do
  usage="$(
    az rest \
      --method get \
      --url "https://management.azure.com/subscriptions/${actual_subscription_id}/providers/Microsoft.Web/locations/${location}/usages?api-version=2024-11-01" \
      --output json
  )"

  sku_free="$(jq -r --arg sku "$PORTFOLIO_APP_SERVICE_SKU" '[.value[]? | select(.name.value == $sku) | (.limit - .currentValue)] | max // 0' <<<"$usage")"
  total_vms_free="$(jq -r '[.value[]? | select((.name.value | ascii_downcase) == "total vms") | (.limit - .currentValue)] | max // 0' <<<"$usage")"

  if ((sku_free < 1 || total_vms_free < 1)); then
    echo "::error::App Service quota changed after qualification in $location."
    exit 1
  fi
done

if [[ -n "$(az group list --query "[?starts_with(name, 'rg-nshop-dev')].name" --output tsv)" ]]; then
  echo '::error::Existing Nordic Shopping development resource groups were found.'
  exit 1
fi

if [[ -n "$(az policy assignment list --query "[?starts_with(name, 'nshop-dev-')].name" --output tsv)" ]]; then
  echo '::error::Existing Nordic Shopping development policy assignments were found.'
  exit 1
fi

if [[ -n "$(az consumption budget list --query "[?name=='budget-nshop-dev-monthly' || name=='budget-nshop-monthly'].name" --output tsv)" ]]; then
  echo '::error::An existing Nordic Shopping development budget was found.'
  exit 1
fi

for region_code in "$PORTFOLIO_PRIMARY_REGION_CODE" "$PORTFOLIO_SECONDARY_REGION_CODE"; do
  key_vault_name="kv-nshop-dev-${region_code}"

  if [[ -n "$(az keyvault list --query "[?name=='${key_vault_name}'].name" --output tsv)" ||
    -n "$(az keyvault list-deleted --query "[?name=='${key_vault_name}'].name" --output tsv)" ]]; then
    echo "::error::An active or soft-deleted Key Vault already exists: $key_vault_name"
    exit 1
  fi
done

for deployment_name in \
  "deploy-resource-groups-dev-${PORTFOLIO_PRIMARY_REGION_CODE}" \
  "deploy-policy-assignments-dev-${PORTFOLIO_PRIMARY_REGION_CODE}" \
  "deploy-budget-dev-${PORTFOLIO_PRIMARY_REGION_CODE}"; do
  existing_location="$(az deployment sub show --name "$deployment_name" --query location --output tsv 2>/dev/null || true)"
  if [[ -n "$existing_location" && "${existing_location,,}" != "${PORTFOLIO_PRIMARY_LOCATION,,}" ]]; then
    echo "::error::Deployment record has an incompatible location: $deployment_name"
    exit 1
  fi
done

bash infra/bicep/environments/portfolio/validate.portfolio.sh "$parameter_file"

echo 'PASS: Subscription, tenant, provider registrations and deployment roles are valid.'
echo 'PASS: Both App Service worker quotas and Total Regional VMs are sufficient.'
echo 'PASS: Existing resources, policies, budgets, Key Vaults and deployment records are safe.'
