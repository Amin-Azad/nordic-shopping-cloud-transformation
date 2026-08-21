#!/usr/bin/env bash
set -euo pipefail

candidate_locations="${PORTFOLIO_CANDIDATE_LOCATIONS:-westeurope,northeurope,swedencentral,norwayeast,germanywestcentral,francecentral,uksouth,polandcentral,spaincentral,denmarkeast,canadacentral}"
candidate_skus="${PORTFOLIO_CANDIDATE_APP_SERVICE_SKUS:-S1,P0v3,P1v3,P0v4,P1v4}"
sql_sku="${PORTFOLIO_SQL_SKU:-GP_S_Gen5_1}"
required_workers="${PORTFOLIO_REQUIRED_WORKERS:-1}"
report_directory="${PORTFOLIO_REPORT_DIRECTORY:-reports/portfolio}"
report_file="$report_directory/region-qualification.portfolio.md"
selection_file="$report_directory/selected-profile.portfolio.env"

for command_name in az jq; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "::error::Required command is unavailable: $command_name"
    exit 1
  fi
done

subscription_id="$(az account show --query id --output tsv)"
IFS=',' read -r -a locations <<<"$candidate_locations"
IFS=',' read -r -a skus <<<"$candidate_skus"
declare -A qualified_regions_by_sku=()

mkdir -p "$report_directory"
{
  echo '# Portfolio region qualification'
  echo
  echo '| Region | SQL available | App Service SKU | SKU workers free | Total VMs free | Qualified |'
  echo '|---|---|---|---:|---:|---|'
} >"$report_file"

region_code() {
  case "$1" in
    westeurope) echo 'weu' ;;
    northeurope) echo 'neu' ;;
    swedencentral) echo 'swc' ;;
    norwayeast) echo 'noe' ;;
    germanywestcentral) echo 'gwc' ;;
    francecentral) echo 'frc' ;;
    uksouth) echo 'uks' ;;
    polandcentral) echo 'plc' ;;
    spaincentral) echo 'spc' ;;
    denmarkeast) echo 'dke' ;;
    canadacentral) echo 'cac' ;;
    *) return 1 ;;
  esac
}

for location in "${locations[@]}"; do
  if ! region_code "$location" >/dev/null; then
    echo "::error::No approved region code is configured for $location."
    exit 1
  fi

  if ! sql_capability="$(
    az rest \
      --method get \
      --url "https://management.azure.com/subscriptions/${subscription_id}/providers/Microsoft.Sql/locations/${location}/capabilities?api-version=2021-11-01" \
      --output json 2>"$report_directory/sql-${location}.stderr.txt"
  )"; then
    echo "WARN: SQL capabilities could not be read for $location."
    continue
  fi

  sql_available=false
  if jq -e \
    --arg sku "$sql_sku" \
    '
      (.status == "Available" or .status == "Default") and
      any(
        .supportedServerVersions[]? |
        select(.name == "12.0") |
        .supportedEditions[]? |
        select(.name == "GeneralPurpose") |
        .supportedServiceLevelObjectives[]?;
        .name == $sku and (.status == "Available" or .status == "Default")
      )
    ' <<<"$sql_capability" >/dev/null; then
    sql_available=true
  fi

  if ! app_service_usage="$(
    az rest \
      --method get \
      --url "https://management.azure.com/subscriptions/${subscription_id}/providers/Microsoft.Web/locations/${location}/usages?api-version=2024-11-01" \
      --output json 2>"$report_directory/app-service-${location}.stderr.txt"
  )"; then
    echo "WARN: App Service quotas could not be read for $location."
    continue
  fi

  total_vms_free="$(
    jq -r '
      [.value[]? | select((.name.value | ascii_downcase) == "total vms") | (.limit - .currentValue)]
      | max // 0
    ' <<<"$app_service_usage"
  )"

  for sku in "${skus[@]}"; do
    if [[ ! "$sku" =~ ^(S[123]|P[0-3]v[234])$ ]]; then
      echo "::error::App Service SKU does not support the existing staging-slot design: $sku"
      exit 1
    fi

    sku_workers_free="$(
      jq -r \
        --arg sku "$sku" \
        '[.value[]? | select(.name.value == $sku) | (.limit - .currentValue)] | max // 0' \
        <<<"$app_service_usage"
    )"

    qualified=false
    if [[ "$sql_available" == 'true' ]] &&
      ((sku_workers_free >= required_workers)) &&
      ((total_vms_free >= required_workers)); then
      qualified=true
      qualified_regions_by_sku["$sku"]="${qualified_regions_by_sku[$sku]:-} $location"
    fi

    printf '| %s | %s | %s | %s | %s | %s |\n' \
      "$location" "$sql_available" "$sku" "$sku_workers_free" "$total_vms_free" "$qualified" \
      >>"$report_file"
  done
done

cat "$report_file"

selected_sku=''
primary_location=''
secondary_location=''

for sku in "${skus[@]}"; do
  read -r -a compatible_regions <<<"${qualified_regions_by_sku[$sku]:-}"
  if ((${#compatible_regions[@]} >= 2)); then
    selected_sku="$sku"
    primary_location="${compatible_regions[0]}"
    secondary_location="${compatible_regions[1]}"
    break
  fi
done

if [[ -z "$selected_sku" ]]; then
  echo '::error::No slot-capable App Service SKU qualified in two SQL-compatible regions.'
  echo '::error::The original two-region architecture cannot be deployed under the current subscription quotas.'
  exit 1
fi

primary_region_code="$(region_code "$primary_location")"
secondary_region_code="$(region_code "$secondary_location")"

{
  printf 'PORTFOLIO_PRIMARY_LOCATION=%s\n' "$primary_location"
  printf 'PORTFOLIO_PRIMARY_REGION_CODE=%s\n' "$primary_region_code"
  printf 'PORTFOLIO_SECONDARY_LOCATION=%s\n' "$secondary_location"
  printf 'PORTFOLIO_SECONDARY_REGION_CODE=%s\n' "$secondary_region_code"
  printf 'PORTFOLIO_APP_SERVICE_SKU=%s\n' "$selected_sku"
} >"$selection_file"

if [[ -n "${GITHUB_ENV:-}" ]]; then
  cat "$selection_file" >>"$GITHUB_ENV"
fi

echo "PASS: Selected $selected_sku in $primary_location and $secondary_location."
