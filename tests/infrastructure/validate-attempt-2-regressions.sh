#!/usr/bin/env bash
set -euo pipefail

compiled_template="${1:-/tmp/nshop-bicep-build/main.json}"
readiness_script="scripts/check-dev-subscription-readiness.sh"

bash -n "$readiness_script"

grep -F 'available_sku_workers=' "$readiness_script" >/dev/null
grep -F 'available_total_vms=' "$readiness_script" >/dev/null
grep -F '(.name.value | ascii_downcase) == "total vms"' "$readiness_script" >/dev/null
grep -F 'available_sku_workers < app_service_workers' "$readiness_script" >/dev/null
grep -F 'available_total_vms < app_service_workers' "$readiness_script" >/dev/null

jq -e '
  [
    ..
    | objects
    | select(.type? == "Microsoft.Sql/servers")
  ] as $servers
  | ($servers | length) >= 2
  and all(
    $servers[];
    .properties.administrators.administratorType == "ActiveDirectory"
    and .properties.administrators.principalType == "Group"
    and .properties.administrators.azureADOnlyAuthentication == true
  )
' "$compiled_template" >/dev/null

jq -e '
  [
    ..
    | objects
    | select(
        .type? == "Microsoft.Sql/servers/administrators"
        or .type? == "Microsoft.Sql/servers/azureADOnlyAuthentications"
      )
  ]
  | length == 0
' "$compiled_template" >/dev/null

echo "PASS: Attempt-2 quota and SQL Entra regressions are guarded."
