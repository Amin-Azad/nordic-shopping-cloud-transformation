#!/usr/bin/env bash
set -euo pipefail

parameter_file="${1:-infra/bicep/environments/dev/main.bicepparam}"

required_commands=(
  az
  jq
)

for command_name in "${required_commands[@]}"; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "::error::Required command is unavailable: $command_name"
    exit 1
  fi
done

required_variables=(
  EXPECTED_SUBSCRIPTION_ID
  EXPECTED_TENANT_ID
  DEPLOY_PRINCIPAL_OBJECT_ID
  SQL_ENTRA_ADMIN_OBJECT_ID
  DATABASE_ADMINISTRATORS_GROUP_OBJECT_ID
)

for variable_name in "${required_variables[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "::error::Required environment variable is missing: $variable_name"
    exit 1
  fi
done

temporary_directory="$(mktemp -d)"
compiled_parameters="$temporary_directory/dev.parameters.json"

cleanup() {
  rm -rf "$temporary_directory"
}
trap cleanup EXIT

az bicep build-params \
  --file "$parameter_file" \
  --outfile "$compiled_parameters" \
  >/dev/null

parameter_value() {
  jq -r --arg name "$1" '.parameters[$name].value' \
    "$compiled_parameters"
}

environment_name="$(parameter_value environmentName)"
primary_location="$(parameter_value primaryLocation)"
primary_region_code="$(parameter_value primaryRegionCode)"
secondary_location="$(parameter_value secondaryLocation)"
secondary_region_code="$(parameter_value secondaryRegionCode)"
sql_sku="$(parameter_value sqlDatabaseSkuName)"
sql_admin_login="$(parameter_value sqlEntraAdminLogin)"
sql_admin_object_id="$(parameter_value sqlEntraAdminObjectId)"
sql_admin_tenant_id="$(parameter_value sqlEntraAdminTenantId)"
app_service_sku="$(parameter_value appServicePlanSkuName)"
app_service_workers="$(parameter_value appServicePlanWorkerCount)"

if [[ "$environment_name" != "dev" ]]; then
  echo "::error::Readiness checks are restricted to dev."
  exit 1
fi

if [[ "$primary_location" != "germanywestcentral" ||
  "$primary_region_code" != "gwc" ||
  "$secondary_location" != "canadacentral" ||
  "$secondary_region_code" != "cac" ]]; then
  echo "::error::Unexpected dev region configuration."
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

if [[ "$sql_admin_tenant_id" != "$EXPECTED_TENANT_ID" ]]; then
  echo "::error::SQL administrator tenant does not match Azure login."
  exit 1
fi

if [[ "$sql_admin_login" != "nshop-database-administrators" ]]; then
  echo "::error::Unexpected SQL administrator display name."
  exit 1
fi

if [[ "$sql_admin_object_id" != "$DATABASE_ADMINISTRATORS_GROUP_OBJECT_ID" ]]; then
  echo "::error::SQL administrator does not match the database-administrators group."
  exit 1
fi

if [[ "$sql_admin_object_id" != "$SQL_ENTRA_ADMIN_OBJECT_ID" ]]; then
  echo "::error::Compiled SQL administrator does not match the configured SQL administrator."
  exit 1
fi

echo "PASS: Subscription and tenant match."

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
  Microsoft.CognitiveServices
  Microsoft.CostManagement
)

for provider in "${required_providers[@]}"; do
  registration_state="$(
    az provider show \
      --namespace "$provider" \
      --query registrationState \
      --output tsv
  )"

  if [[ "${registration_state,,}" != "registered" ]]; then
    echo "::error::Resource provider is not registered: $provider"
    exit 1
  fi
done

echo "PASS: Required resource providers are registered."

for location in "$primary_location" "$secondary_location"; do
  sql_capability="$(
    az rest \
      --method get \
      --url "https://management.azure.com/subscriptions/${actual_subscription_id}/providers/Microsoft.Sql/locations/${location}/capabilities?api-version=2021-11-01" \
      --output json
  )"

  if ! jq -e \
    --arg sku "$sql_sku" \
    '
      (.status == "Available" or .status == "Default") and
      any(
        .supportedServerVersions[] |
        select(.name == "12.0") |
        .supportedEditions[] |
        select(.name == "GeneralPurpose") |
        .supportedServiceLevelObjectives[];
        .name == $sku and
        (.status == "Available" or .status == "Default")
      )
    ' <<<"$sql_capability" >/dev/null; then
    echo "::error::SQL SKU is unavailable for this subscription in $location."
    exit 1
  fi
done

echo "PASS: SQL provisioning and exact SKU are available."

for location in "$primary_location" "$secondary_location"; do
  app_service_usage="$(
    az rest \
      --method get \
      --url "https://management.azure.com/subscriptions/${actual_subscription_id}/providers/Microsoft.Web/locations/${location}/usages?api-version=2024-11-01" \
      --output json
  )"

  available_workers="$(
    jq -r \
      --arg sku "$app_service_sku" \
      '
        [
          .value[]
          | select(.name.value == $sku)
          | (.limit - .currentValue)
        ]
        | max // 0
      ' <<<"$app_service_usage"
  )"

  if ((available_workers < app_service_workers)); then
    echo "::error::Insufficient $app_service_sku quota in $location."
    exit 1
  fi
done

echo "PASS: App Service quota is sufficient in both regions."

if [[ "${SKIP_ENTRA_DIRECTORY_LOOKUP:-false}" == "true" ]]; then
  echo "INFO: Entra directory lookup skipped for the OIDC identity."
  echo "INFO: Compiled SQL administrator IDs and display name still matched."
else
  group_json="$(
    az ad group show \
      --group "$DATABASE_ADMINISTRATORS_GROUP_OBJECT_ID" \
      --output json 2>/dev/null
  )" || {
    echo "::error::Unable to resolve the database-administrators group."
    exit 1
  }

  if ! jq -e \
    --arg id "$DATABASE_ADMINISTRATORS_GROUP_OBJECT_ID" \
    '
      .id == $id and
      .displayName == "nshop-database-administrators" and
      .securityEnabled == true
    ' <<<"$group_json" >/dev/null; then
    echo "::error::Database-administrators group metadata is inconsistent."
    exit 1
  fi

  echo "PASS: SQL administrator group exists and is security-enabled."
fi

required_deploy_roles=(
  Contributor
  "User Access Administrator"
  "Resource Policy Contributor"
  "Cost Management Contributor"
)

deploy_role_assignments="$(
  az role assignment list \
    --all \
    --include-inherited \
    --query "[?principalId=='${DEPLOY_PRINCIPAL_OBJECT_ID}'].roleDefinitionName" \
    --output json
)"

for required_role in "${required_deploy_roles[@]}"; do
  if ! jq -e \
    --arg role "$required_role" \
    'index($role) != null' \
    <<<"$deploy_role_assignments" >/dev/null; then
    echo "::error::Deployment identity lacks required role: $required_role"
    exit 1
  fi
done

echo "PASS: Deployment and cleanup identity permissions are present."

existing_resource_groups="$(
  az group list \
    --query "[?starts_with(name, 'rg-nshop-dev')].name" \
    --output tsv
)"

if [[ -n "$existing_resource_groups" ]]; then
  echo "::error::Existing Nordic Shopping dev resource groups were found."
  exit 1
fi

existing_policy_assignments="$(
  az policy assignment list \
    --query "[?starts_with(name, 'nshop-dev-')].name" \
    --output tsv
)"

if [[ -n "$existing_policy_assignments" ]]; then
  echo "::error::Existing Nordic Shopping dev policy assignments were found."
  exit 1
fi

existing_budget="$(
  az consumption budget list \
    --query "[?name=='budget-nshop-dev-monthly' || name=='budget-nshop-monthly'].name" \
    --output tsv
)"

if [[ -n "$existing_budget" ]]; then
  echo "::error::Existing Nordic Shopping dev budget was found."
  exit 1
fi

existing_key_vaults="$(
  az keyvault list \
    --query "[?starts_with(name, 'kv-nshop-dev-')].name" \
    --output tsv
)"

if [[ -n "$existing_key_vaults" ]]; then
  echo "::error::Existing Nordic Shopping dev Key Vaults were found."
  exit 1
fi

deleted_key_vaults="$(
  az keyvault list-deleted \
    --query "[?starts_with(name, 'kv-nshop-dev-')].name" \
    --output tsv
)"

if [[ -n "$deleted_key_vaults" ]]; then
  echo "::error::Soft-deleted Nordic Shopping dev Key Vaults were found."
  exit 1
fi

echo "PASS: No previous dev resources, policies, budget, or Key Vault conflicts exist."
echo "Dev subscription readiness checks passed."
