#!/usr/bin/env bash
set -euo pipefail

readiness_script="scripts/check-dev-subscription-readiness.sh"
sql_server_module="infra/bicep/modules/data/sql-server.bicep"

bash -n "$readiness_script"

require_source_guard() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if ! grep -F "$pattern" "$file" >/dev/null; then
    echo "::error::Missing regression guard: $description"
    exit 1
  fi
}

require_source_guard "$readiness_script" 'available_sku_workers=' 'SKU-specific worker quota calculation'
require_source_guard "$readiness_script" 'available_total_vms=' 'Total VMs quota calculation'
require_source_guard "$readiness_script" '(.name.value | ascii_downcase) == "total vms"' 'Total VMs usage record selection'
require_source_guard "$readiness_script" 'available_sku_workers < app_service_workers' 'SKU-specific worker quota enforcement'
require_source_guard "$readiness_script" 'available_total_vms < app_service_workers' 'Total VMs quota enforcement'

require_source_guard "$sql_server_module" 'administrators: {' 'inline SQL Entra administrator'
require_source_guard "$sql_server_module" "administratorType: 'ActiveDirectory'" 'Active Directory administrator type'
require_source_guard "$sql_server_module" "principalType: 'Group'" 'SQL administrator group principal type'
require_source_guard "$sql_server_module" 'login: entraAdminLogin' 'SQL administrator login parameter'
require_source_guard "$sql_server_module" 'sid: entraAdminObjectId' 'SQL administrator object ID'
require_source_guard "$sql_server_module" 'tenantId: entraAdminTenantId' 'SQL administrator tenant ID'
require_source_guard "$sql_server_module" 'azureADOnlyAuthentication: true' 'Entra-only authentication at server creation'

if grep -E \
  "resource[[:space:]]+(entraAdministrator|entraOnlyAuthentication)[[:space:]]" \
  "$sql_server_module" >/dev/null; then
  echo "::error::Obsolete SQL administrator child resources remain in the SQL server module."
  exit 1
fi

qualification_script="scripts/qualify-dev-regions.sh"
bash -n "$qualification_script"
require_source_guard "$qualification_script" 'sql_available' 'SQL SKU qualification'
require_source_guard "$qualification_script" 'sku_workers_free' 'App Service SKU qualification'
require_source_guard "$qualification_script" 'total_vms_free' 'Total VMs qualification'
require_source_guard "$qualification_script" 'qualified_regions[@]' 'two-region qualification result'

echo "PASS: Attempt-2 quota and SQL Entra regressions are guarded."
