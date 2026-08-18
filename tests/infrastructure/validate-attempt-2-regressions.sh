#!/usr/bin/env bash
set -euo pipefail

compiled_template="${1:-/tmp/nshop-bicep-build/main.json}"
readiness_script="scripts/check-dev-subscription-readiness.sh"

bash -n "$readiness_script"

require_readiness_guard() {
  local pattern="$1"
  local description="$2"

  if ! grep -F "$pattern" "$readiness_script" >/dev/null; then
    echo "::error::Missing readiness guard: $description"
    exit 1
  fi
}

require_readiness_guard 'available_sku_workers=' 'SKU-specific worker quota calculation'
require_readiness_guard 'available_total_vms=' 'Total VMs quota calculation'
require_readiness_guard '(.name.value | ascii_downcase) == "total vms"' 'Total VMs usage record selection'
require_readiness_guard 'available_sku_workers < app_service_workers' 'SKU-specific worker quota enforcement'
require_readiness_guard 'available_total_vms < app_service_workers' 'Total VMs quota enforcement'

if ! jq -e '
  [
    ..
    | objects
    | select(.type? == "Microsoft.Sql/servers")
  ] as $servers
  | ($servers | length) >= 1
  and all(
    $servers[];
    .properties.administrators.administratorType == "ActiveDirectory"
    and .properties.administrators.principalType == "Group"
    and .properties.administrators.azureADOnlyAuthentication == true
  )
' "$compiled_template" >/dev/null; then
  echo "::error::Compiled SQL servers are missing the inline Entra-only group administrator."
  exit 1
fi

if ! jq -e '
  [
    ..
    | objects
    | select(
        .type? == "Microsoft.Sql/servers/administrators"
        or .type? == "Microsoft.Sql/servers/azureADOnlyAuthentications"
      )
  ]
  | length == 0
' "$compiled_template" >/dev/null; then
  echo "::error::Obsolete SQL administrator child resources remain in the compiled template."
  exit 1
fi

echo "PASS: Attempt-2 quota and SQL Entra regressions are guarded."
