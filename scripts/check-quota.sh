#!/usr/bin/env bash
set -euo pipefail

# Read-only Azure quota and regional eligibility check.
# Usage: bash scripts/check-quota.sh
# Example: REGIONS="swedencentral westeurope" bash scripts/check-quota.sh

REGIONS="${REGIONS:-swedencentral northeurope westeurope norwayeast germanywestcentral}"
OUT="quota-check-$(date +%Y%m%d-%H%M).txt"

{
  echo "=================================================="
  echo " 1. SUBSCRIPTION"
  echo "=================================================="
  SUB="$(az account show --query id -o tsv)"
  az account show --query "{name:name, state:state}" -o table
  echo
  echo "Offer type (look at quotaId):"
  az rest --method get \
    --url "https://management.azure.com/subscriptions/${SUB}?api-version=2022-12-01" \
    --query "subscriptionPolicies" -o table

  echo
  echo "=================================================="
  echo " 2. RESOURCE PROVIDERS"
  echo "=================================================="
  for p in Microsoft.Web Microsoft.Sql Microsoft.KeyVault Microsoft.Network \
           Microsoft.Cdn Microsoft.OperationalInsights Microsoft.Insights Microsoft.Quota; do
    printf "%-32s %s\n" "$p" "$(az provider show -n "$p" --query registrationState -o tsv 2>/dev/null)"
  done

  for r in $REGIONS; do
    echo
    echo "=================================================="
    echo " REGION: $r"
    echo "=================================================="

    echo "--- App Service (Microsoft.Web) ---"
    az rest --method get \
      --url "https://management.azure.com/subscriptions/${SUB}/providers/Microsoft.Web/locations/${r}/usages?api-version=2026-07-15" \
      --query "value[].{quota:name.localizedValue, used:currentValue, limit:limit}" -o table 2>&1

    echo
    echo "--- Azure SQL: provisioning status ---"
    az rest --method get \
      --url "https://management.azure.com/subscriptions/${SUB}/providers/Microsoft.Sql/locations/${r}/capabilities?api-version=2021-11-01" \
      --query "{region:name, status:status, reason:reason}" -o table 2>&1

    echo
    echo "--- Azure SQL: usages ---"
    az sql list-usages -l "$r" -o table 2>&1
  done

  echo
  echo "=================================================="
  echo " WHAT TO LOOK FOR"
  echo "=================================================="
  echo "App Service Total Regional VMs = 0 -> region cannot host this profile"
  echo "SQL status not Available           -> choose another region"
  echo "SQL server quota below 2           -> full two-region portfolio profile cannot deploy"
  echo "Use the portfolio qualification workflow for the final deployment decision"
} 2>&1 | tee "$OUT"

echo
echo "Saved to $OUT"
