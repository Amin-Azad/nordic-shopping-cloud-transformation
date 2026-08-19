#!/usr/bin/env bash
set -euo pipefail

main_template="infra/bicep/main.bicep"
database_module="infra/bicep/modules/data/sql-database.bicep"
dev_parameters="infra/bicep/environments/dev/main.bicepparam"
prod_parameters="infra/bicep/environments/prod/main.bicepparam"

require_source_guard() {
  local file="$1"
  local pattern="$2"
  local description="$3"

  if ! grep -F "$pattern" "$file" >/dev/null; then
    echo "::error::Missing design-consistency guard: $description"
    exit 1
  fi
}

require_source_guard "$main_template"   "param primarySqlDatabaseZoneRedundant bool = true"   "separate primary SQL zone-redundancy parameter"

require_source_guard "$main_template"   "param secondarySqlDatabaseZoneRedundant bool = false"   "separate secondary SQL zone-redundancy parameter"

require_source_guard "$main_template"   "module secondarySqlDatabaseModule './modules/data/sql-database.bicep'"   "explicit secondary SQL database deployment"

require_source_guard "$main_template"   "zoneRedundant: secondarySqlDatabaseZoneRedundant"   "secondary SQL zone-redundancy wiring"

require_source_guard "$main_template"   "createMode: 'Secondary'"   "secondary geo-replica creation mode"

require_source_guard "$main_template"   "sourceDatabaseId: primaryRegionalPlatformModule.outputs.sqlDatabaseId"   "secondary database source relationship"

require_source_guard "$main_template"   "    secondarySqlDatabaseModule"   "failover-group dependency on the secondary database"

require_source_guard "$database_module"   "sourceDatabaseId: sourceDatabaseId"   "secondary database source passed to Azure"

require_source_guard "$dev_parameters"   "param primarySqlDatabaseZoneRedundant = false"   "development primary SQL setting"

require_source_guard "$dev_parameters"   "param secondarySqlDatabaseZoneRedundant = false"   "development secondary SQL setting"

require_source_guard "$prod_parameters"   "param primarySqlDatabaseZoneRedundant = true"   "production primary SQL setting"

require_source_guard "$prod_parameters"   "param secondarySqlDatabaseZoneRedundant = false"   "production secondary SQL setting"

if grep -F "param sqlDatabaseZoneRedundant bool" "$main_template" >/dev/null; then
  echo "::error::Legacy global SQL zone-redundancy parameter remains."
  exit 1
fi

echo "PASS: SQL primary and secondary resilience settings are independently guarded."
