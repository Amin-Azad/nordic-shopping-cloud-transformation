#!/usr/bin/env bash
set -euo pipefail

parameter_file="${1:-infra/bicep/environments/portfolio/main.portfolio.bicepparam}"
temporary_directory="$(mktemp -d)"
compiled_parameters="$temporary_directory/portfolio.parameters.json"
trap 'rm -rf "$temporary_directory"' EXIT

required_variables=(
  BUDGET_ALERT_EMAIL
  OPERATIONAL_ALERT_EMAIL
  SECURITY_ALERT_EMAIL
  COST_ALERT_EMAIL
  AZURE_TENANT_ID
  SQL_ENTRA_ADMIN_OBJECT_ID
  PLATFORM_ADMINISTRATORS_GROUP_OBJECT_ID
  DEVELOPERS_GROUP_OBJECT_ID
  OPERATIONS_GROUP_OBJECT_ID
  SECURITY_READERS_GROUP_OBJECT_ID
  COST_READERS_GROUP_OBJECT_ID
  DATABASE_ADMINISTRATORS_GROUP_OBJECT_ID
  AUDITORS_GROUP_OBJECT_ID
  PORTFOLIO_PRIMARY_LOCATION
  PORTFOLIO_PRIMARY_REGION_CODE
  PORTFOLIO_SECONDARY_LOCATION
  PORTFOLIO_SECONDARY_REGION_CODE
  PORTFOLIO_APP_SERVICE_SKU
  PORTFOLIO_SQL_ADMIN_LOGIN
  PORTFOLIO_BUDGET_START_DATE
  PORTFOLIO_BUDGET_END_DATE
)

for variable_name in "${required_variables[@]}"; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "::error::Required environment variable is missing: $variable_name"
    exit 1
  fi
done

az bicep build-params \
  --file "$parameter_file" \
  --outfile "$compiled_parameters" \
  >/dev/null

jq -e '
  def value($name): .parameters[$name].value;

  value("environmentName") == "dev" and
  value("primaryLocation") == env.PORTFOLIO_PRIMARY_LOCATION and
  value("primaryRegionCode") == env.PORTFOLIO_PRIMARY_REGION_CODE and
  value("secondaryLocation") == env.PORTFOLIO_SECONDARY_LOCATION and
  value("secondaryRegionCode") == env.PORTFOLIO_SECONDARY_REGION_CODE and
  value("primaryLocation") != value("secondaryLocation") and
  value("primaryRegionCode") != value("secondaryRegionCode") and
  value("policyAuditEffect") == "Audit" and
  value("budgetAmount") > 0 and
  value("budgetAmount") <= 900 and
  value("enableResourceLocks") == false and
  value("enableKeyVaultPurgeProtection") == false and
  value("storageSkuName") == "Standard_LRS" and
  value("sqlEntraAdminLogin") == env.PORTFOLIO_SQL_ADMIN_LOGIN and
  value("sqlEntraAdminTenantId") == env.AZURE_TENANT_ID and
  value("sqlEntraAdminObjectId") == env.SQL_ENTRA_ADMIN_OBJECT_ID and
  value("sqlEntraAdminObjectId") == value("databaseAdministratorsGroupObjectId") and
  value("sqlDatabaseSkuName") == "GP_S_Gen5_1" and
  value("sqlDatabaseSkuCapacity") == 1 and
  value("primarySqlDatabaseZoneRedundant") == false and
  value("secondarySqlDatabaseZoneRedundant") == false and
  value("sqlFailoverPolicy") == "Manual" and
  value("appServicePlanSkuName") == env.PORTFOLIO_APP_SERVICE_SKU and
  (value("appServicePlanSkuName") | test("^(S[123]|P[0-3]v[234])$")) and
  value("appServicePlanWorkerCount") == 1 and
  value("appServicePlanZoneRedundant") == false and
  value("createAllStagingSlots") == false and
  value("autoscaleEnabled") == false and
  value("enableAiServicesAccount") == false and
  value("enableAiModelDeployment") == false
' "$compiled_parameters" >/dev/null || {
  echo "::error::Portfolio parameters violate the deployment safety policy."
  exit 1
}

if [[ "${PORTFOLIO_ALLOW_TEST_VALUES:-false}" != "true" ]]; then
  for variable_name in \
    SQL_ENTRA_ADMIN_OBJECT_ID \
    PLATFORM_ADMINISTRATORS_GROUP_OBJECT_ID \
    DEVELOPERS_GROUP_OBJECT_ID \
    OPERATIONS_GROUP_OBJECT_ID \
    SECURITY_READERS_GROUP_OBJECT_ID \
    COST_READERS_GROUP_OBJECT_ID \
    DATABASE_ADMINISTRATORS_GROUP_OBJECT_ID \
    AUDITORS_GROUP_OBJECT_ID; do
    if [[ "${!variable_name}" == 00000000-0000-0000-0000-0000000000* ]]; then
      echo "::error::Placeholder object ID detected: $variable_name"
      exit 1
    fi
  done

  for variable_name in \
    BUDGET_ALERT_EMAIL \
    OPERATIONAL_ALERT_EMAIL \
    SECURITY_ALERT_EMAIL \
    COST_ALERT_EMAIL; do
    if [[ "${!variable_name}" == *.invalid ]]; then
      echo "::error::Placeholder email detected: $variable_name"
      exit 1
    fi
  done
fi

echo "PASS: Portfolio parameters preserve the original two-region architecture."
echo "PASS: Portfolio cost, identity, SQL and App Service safety checks passed."
