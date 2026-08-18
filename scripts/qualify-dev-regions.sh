#!/usr/bin/env bash
set -euo pipefail

candidate_locations="${1:-germanywestcentral,canadacentral,swedencentral,northeurope,westeurope,uksouth,norwayeast}"
candidate_app_service_skus="${2:-P0v4,B1}"
sql_sku="${3:-GP_S_Gen5_1}"
required_workers="${REQUIRED_APP_SERVICE_WORKERS:-1}"
report_file="${REGION_QUALIFICATION_REPORT:-reports/dev-region-qualification.md}"

for command_name in az jq; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "::error::Required command is unavailable: $command_name"
    exit 1
  fi
done

subscription_id="$(az account show --query id --output tsv)"
IFS=',' read -r -a locations <<<"$candidate_locations"
IFS=',' read -r -a app_service_skus <<<"$candidate_app_service_skus"

mkdir -p "$(dirname "$report_file")"
{
  echo "# Dev region qualification"
  echo
  echo "| Region | SQL $sql_sku | App Service SKU | SKU workers free | Total VMs free | Qualified |"
  echo "|---|---:|---|---:|---:|---:|"
} >"$report_file"

qualified_regions=()

for location in "${locations[@]}"; do
  sql_capability="$(
    az rest \
      --method get \
      --url "https://management.azure.com/subscriptions/${subscription_id}/providers/Microsoft.Sql/locations/${location}/capabilities?api-version=2021-11-01" \
      --output json
  )"

  sql_available=false
  if jq -e \
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
    sql_available=true
  fi

  app_service_usage="$(
    az rest \
      --method get \
      --url "https://management.azure.com/subscriptions/${subscription_id}/providers/Microsoft.Web/locations/${location}/usages?api-version=2024-11-01" \
      --output json
  )"

  total_vms_free="$(
    jq -r '
      [
        .value[]
        | select((.name.value | ascii_downcase) == "total vms")
        | (.limit - .currentValue)
      ]
      | max // 0
    ' <<<"$app_service_usage"
  )"

  region_qualified=false

  for app_service_sku in "${app_service_skus[@]}"; do
    sku_workers_free="$(
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

    qualified=false
    if [[ "$sql_available" == "true" ]] &&
      ((sku_workers_free >= required_workers)) &&
      ((total_vms_free >= required_workers)); then
      qualified=true
      region_qualified=true
    fi

    printf '| %s | %s | %s | %s | %s | %s |\n' \
      "$location" \
      "$sql_available" \
      "$app_service_sku" \
      "$sku_workers_free" \
      "$total_vms_free" \
      "$qualified" \
      >>"$report_file"
  done

  if [[ "$region_qualified" == "true" ]]; then
    qualified_regions+=("$location")
  fi
done

cat "$report_file"

if (("${#qualified_regions[@]}" < 2)); then
  echo "::error::Fewer than two subscription-compatible dev regions were found."
  exit 1
fi

printf 'PASS: Compatible dev regions: %s\n' "${qualified_regions[*]}"
