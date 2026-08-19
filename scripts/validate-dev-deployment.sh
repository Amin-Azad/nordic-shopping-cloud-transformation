#!/usr/bin/env bash
set -euo pipefail

parameter_file="${1:-infra/bicep/environments/dev/main.bicepparam}"
temporary_directory="$(mktemp -d)"
compiled_parameters="$temporary_directory/dev.parameters.json"

cleanup() {
  rm -rf "$temporary_directory"
}
trap cleanup EXIT

required_variables=(
  BUDGET_ALERT_EMAIL
  OPERATIONAL_ALERT_EMAIL
  SECURITY_ALERT_EMAIL
  COST_ALERT_EMAIL
  SQL_ENTRA_ADMIN_OBJECT_ID
  PLATFORM_ADMINISTRATORS_GROUP_OBJECT_ID
  DEVELOPERS_GROUP_OBJECT_ID
  OPERATIONS_GROUP_OBJECT_ID
  SECURITY_READERS_GROUP_OBJECT_ID
  COST_READERS_GROUP_OBJECT_ID
  DATABASE_ADMINISTRATORS_GROUP_OBJECT_ID
  AUDITORS_GROUP_OBJECT_ID
)

for variable_name in "${required_variables[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "::error::Required environment variable is missing: $variable_name"
    exit 1
  fi
done

az bicep build-params \
  --file "$parameter_file" \
  --outfile "$compiled_parameters"

jq -e '
  def value($name): .parameters[$name].value;
  def valid_uuid:
    type == "string" and
    test("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$");

    value("environmentName") == "dev" and
    value("primaryLocation") == "germanywestcentral" and
    value("primaryRegionCode") == "gwc" and
    value("secondaryLocation") == "canadacentral" and
    value("secondaryRegionCode") == "cac" and

    value("policyAuditEffect") == "Audit" and
    value("budgetAmount") > 0 and
    value("budgetAmount") <= 1300 and

    value("enableResourceLocks") == false and
    value("enableKeyVaultPurgeProtection") == false and

    value("storageSkuName") == "Standard_LRS" and

    value("sqlEntraAdminLogin") == "nshop-database-administrators" and
    value("sqlEntraAdminTenantId") == env.AZURE_TENANT_ID and
    (value("sqlEntraAdminObjectId") | valid_uuid) and
    value("sqlEntraAdminObjectId") ==
      value("databaseAdministratorsGroupObjectId") and
    value("sqlDatabaseSkuName") == "GP_S_Gen5_1" and
    value("sqlDatabaseSkuCapacity") == 1 and
    value("sqlDatabaseZoneRedundant") == false and
    value("sqlFailoverPolicy") == "Manual" and

    value("appServicePlanSkuName") == "P0v4" and
    value("appServicePlanWorkerCount") == 1 and
    value("appServicePlanZoneRedundant") == false and
    value("createAllStagingSlots") == false and

    value("autoscaleEnabled") == false and
    value("primaryAutoscaleMinimumCapacity") == 1 and
    value("primaryAutoscaleDefaultCapacity") == 1 and
    value("primaryAutoscaleMaximumCapacity") == 1 and
    value("secondaryAutoscaleMinimumCapacity") == 1 and
    value("secondaryAutoscaleDefaultCapacity") == 1 and
    value("secondaryAutoscaleMaximumCapacity") == 1 and

    value("enableAiServicesAccount") == false and
    value("enableAiModelDeployment") == false
' "$compiled_parameters" >/dev/null || {
  echo "::error::Dev parameters violate the approved cost or safety policy."
  exit 1
}

for variable_name in \
  PLATFORM_ADMINISTRATORS_GROUP_OBJECT_ID \
  DEVELOPERS_GROUP_OBJECT_ID \
  OPERATIONS_GROUP_OBJECT_ID \
  SECURITY_READERS_GROUP_OBJECT_ID \
  COST_READERS_GROUP_OBJECT_ID \
  DATABASE_ADMINISTRATORS_GROUP_OBJECT_ID \
  AUDITORS_GROUP_OBJECT_ID; do
  variable_value="${!variable_name}"

  if [[ "$variable_value" == 00000000-0000-0000-0000-0000000000* ]]; then
    echo "::error::Placeholder object ID detected: $variable_name"
    exit 1
  fi
done

for variable_name in \
  BUDGET_ALERT_EMAIL \
  OPERATIONAL_ALERT_EMAIL \
  SECURITY_ALERT_EMAIL \
  COST_ALERT_EMAIL; do
  variable_value="${!variable_name}"

  if [[ "$variable_value" == *.invalid ]]; then
    echo "::error::Placeholder email detected: $variable_name"
    exit 1
  fi
done

echo "Dev deployment safety checks passed."
