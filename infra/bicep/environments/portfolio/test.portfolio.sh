#!/usr/bin/env bash
set -euo pipefail

portfolio_directory="infra/bicep/environments/portfolio"
temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT

for script in "$portfolio_directory"/*.portfolio.sh; do
  bash -n "$script"
done

mock_directory="$temporary_directory/bin"
mkdir -p "$mock_directory"

cat >"$mock_directory/az" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail

if [[ "$1" == 'account' && "$2" == 'show' ]]; then
  echo 'subscription-for-tests'
  exit 0
fi

if [[ "$1" != 'rest' ]]; then
  echo "Unexpected mocked Azure CLI command: $*" >&2
  exit 1
fi

request="$*"
if [[ "$request" == *'/Microsoft.Sql/'* ]]; then
  cat <<'JSON'
{"status":"Available","supportedServerVersions":[{"name":"12.0","supportedEditions":[{"name":"GeneralPurpose","supportedServiceLevelObjectives":[{"name":"GP_S_Gen5_1","status":"Available"}]}]}]}
JSON
  exit 0
fi

if [[ "$request" == *'/Microsoft.Web/'* ]]; then
  jq -cn \
    --argjson total "${MOCK_TOTAL_VMS:-2}" \
    '{value:[{name:{value:"S1"},limit:2,currentValue:0},{name:{value:"Total VMs"},limit:$total,currentValue:0}]}'
  exit 0
fi

echo "Unexpected Azure management request: $request" >&2
exit 1
MOCK

chmod +x "$mock_directory/az"

PATH="$mock_directory:$PATH" \
  PORTFOLIO_CANDIDATE_LOCATIONS='westeurope,northeurope' \
  PORTFOLIO_CANDIDATE_APP_SERVICE_SKUS='S1' \
  PORTFOLIO_REPORT_DIRECTORY="$temporary_directory/success" \
  bash "$portfolio_directory/qualify-regions.portfolio.sh" \
  >"$temporary_directory/success.log"

profile_file="$temporary_directory/success/selected-profile.portfolio.env"
grep -Fxq 'PORTFOLIO_PRIMARY_LOCATION=westeurope' "$profile_file"
grep -Fxq 'PORTFOLIO_SECONDARY_LOCATION=northeurope' "$profile_file"
grep -Fxq 'PORTFOLIO_APP_SERVICE_SKU=S1' "$profile_file"

if PATH="$mock_directory:$PATH" \
  MOCK_TOTAL_VMS=0 \
  PORTFOLIO_CANDIDATE_LOCATIONS='westeurope,northeurope' \
  PORTFOLIO_CANDIDATE_APP_SERVICE_SKUS='S1' \
  PORTFOLIO_REPORT_DIRECTORY="$temporary_directory/no-vms" \
  bash "$portfolio_directory/qualify-regions.portfolio.sh" \
  >"$temporary_directory/no-vms.log" 2>&1; then
  echo '::error::Region qualification accepted zero Total Regional VMs.'
  exit 1
fi

if PATH="$mock_directory:$PATH" \
  PORTFOLIO_CANDIDATE_LOCATIONS='westeurope,northeurope' \
  PORTFOLIO_CANDIDATE_APP_SERVICE_SKUS='B1' \
  PORTFOLIO_REPORT_DIRECTORY="$temporary_directory/basic-plan" \
  bash "$portfolio_directory/qualify-regions.portfolio.sh" \
  >"$temporary_directory/basic-plan.log" 2>&1; then
  echo '::error::Region qualification accepted a Basic plan despite required staging slots.'
  exit 1
fi

if bash "$portfolio_directory/cleanup.portfolio.sh" 'DELETE-DEV' \
  >"$temporary_directory/cleanup.log" 2>&1; then
  echo '::error::Portfolio cleanup accepted the development confirmation phrase.'
  exit 1
fi

echo 'PASS: Portfolio qualification selects two compatible regions and a slot-capable SKU.'
echo 'PASS: Zero Total Regional VMs and unsupported Basic plans are rejected.'
echo 'PASS: Portfolio cleanup requires its separate confirmation phrase.'
