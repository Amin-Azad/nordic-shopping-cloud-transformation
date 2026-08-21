#!/usr/bin/env bash
set -euo pipefail

runtime_hours="${PORTFOLIO_MAX_RUNTIME_HOURS:-24}"
cost_ceiling="${PORTFOLIO_MAX_ESTIMATED_COST_DKK:-600}"
reserve_dkk="${PORTFOLIO_COST_RESERVE_DKK:-150}"
report_directory="${PORTFOLIO_REPORT_DIRECTORY:-reports/portfolio}"
report_file="$report_directory/cost-estimate.portfolio.md"

for variable_name in PORTFOLIO_PRIMARY_LOCATION PORTFOLIO_SECONDARY_LOCATION PORTFOLIO_APP_SERVICE_SKU; do
  if [[ -z "${!variable_name:-}" ]]; then
    echo "::error::Required environment variable is missing: $variable_name"
    exit 1
  fi
done

if [[ ! "$runtime_hours" =~ ^[0-9]+$ || ! "$cost_ceiling" =~ ^[0-9]+$ || ! "$reserve_dkk" =~ ^[0-9]+$ ]]; then
  echo '::error::Runtime, cost ceiling and reserve must be whole numbers.'
  exit 1
fi

if ((runtime_hours < 1 || runtime_hours > 72 || cost_ceiling > 900)); then
  echo '::error::Runtime must be 1-72 hours and the cost ceiling cannot exceed 900 DKK.'
  exit 1
fi

mkdir -p "$report_directory"

fetch_prices() {
  local filter="$1"
  curl --fail --silent --show-error --get \
    'https://prices.azure.com/api/retail/prices' \
    --data-urlencode 'currencyCode=DKK' \
    --data-urlencode "\$filter=$filter"
}

app_service_hourly=0
sql_hourly=0

for location in "$PORTFOLIO_PRIMARY_LOCATION" "$PORTFOLIO_SECONDARY_LOCATION"; do
  app_prices="$(
    fetch_prices "serviceName eq 'Azure App Service' and armRegionName eq '${location}' and armSkuName eq '${PORTFOLIO_APP_SERVICE_SKU}' and priceType eq 'Consumption'"
  )"

  app_price="$(
    jq -r '
      [
        .Items[]?
        | select((.productName | ascii_downcase | contains("linux")))
        | select(.unitOfMeasure == "1 Hour")
        | select(.retailPrice > 0)
        | .retailPrice
      ]
      | min // empty
    ' <<<"$app_prices"
  )"

  if [[ -z "$app_price" ]]; then
    echo "::error::No exact Linux App Service retail price was found for $PORTFOLIO_APP_SERVICE_SKU in $location."
    exit 1
  fi

  sql_prices="$(
    fetch_prices "serviceName eq 'SQL Database' and armRegionName eq '${location}' and priceType eq 'Consumption'"
  )"

  sql_price="$(
    jq -r '
      [
        .Items[]?
        | select((.productName | ascii_downcase | contains("general purpose")))
        | select((.productName | ascii_downcase | contains("serverless")))
        | select((.skuName | ascii_downcase | contains("gen5")))
        | select(.unitOfMeasure == "1 Hour")
        | select(.retailPrice > 0)
        | .retailPrice
      ]
      | min // empty
    ' <<<"$sql_prices"
  )"

  if [[ -z "$sql_price" ]]; then
    echo "::error::No General Purpose serverless Gen5 SQL retail price was found for $location."
    exit 1
  fi

  app_service_hourly="$(jq -nr --argjson total "$app_service_hourly" --argjson price "$app_price" '$total + $price')"
  sql_hourly="$(jq -nr --argjson total "$sql_hourly" --argjson price "$sql_price" '$total + $price')"
done

private_endpoint_prices="$(
  fetch_prices "serviceName eq 'Azure Private Link' and armRegionName eq '${PORTFOLIO_PRIMARY_LOCATION}' and priceType eq 'Consumption'"
)"

private_endpoint_hourly="$(
  jq -r '
    [
      .Items[]?
      | select((.meterName | ascii_downcase | contains("private endpoint")))
      | select(.unitOfMeasure == "1 Hour")
      | select(.retailPrice > 0)
      | .retailPrice
    ]
    | min // empty
  ' <<<"$private_endpoint_prices"
)"

if [[ -z "$private_endpoint_hourly" ]]; then
  echo '::error::No Azure Private Endpoint hourly retail price was found.'
  exit 1
fi

front_door_prices="$(
  fetch_prices "serviceName eq 'Azure Front Door Service' and priceType eq 'Consumption'"
)"

front_door_hourly="$(
  jq -r '
    [
      .Items[]?
      | select((.productName | ascii_downcase | contains("standard")))
      | select((.meterName | ascii_downcase | contains("base")))
      | select(.unitOfMeasure == "1 Hour")
      | select(.retailPrice > 0)
      | .retailPrice
    ]
    | min // empty
  ' <<<"$front_door_prices"
)"

if [[ -z "$front_door_hourly" ]]; then
  echo '::error::No Azure Front Door Standard hourly base price was found.'
  exit 1
fi

estimated_total="$(
  jq -nr \
    --argjson app "$app_service_hourly" \
    --argjson sql "$sql_hourly" \
    --argjson endpoint "$private_endpoint_hourly" \
    --argjson frontdoor "$front_door_hourly" \
    --argjson hours "$runtime_hours" \
    --argjson reserve "$reserve_dkk" \
    '((($app + $sql + ($endpoint * 6) + $frontdoor) * $hours) + $reserve) | ceil'
)"

{
  echo '# Portfolio deployment cost estimate'
  echo
  echo "- Regions: $PORTFOLIO_PRIMARY_LOCATION and $PORTFOLIO_SECONDARY_LOCATION"
  echo "- App Service: two Linux $PORTFOLIO_APP_SERVICE_SKU plans"
  echo '- SQL: two General Purpose serverless Gen5 databases'
  echo '- Private endpoints: six'
  echo '- Azure Front Door: Standard'
  echo "- Maximum runtime: $runtime_hours hours"
  echo "- Reserve for storage, monitoring, DNS, bandwidth and pricing variation: $reserve_dkk DKK"
  echo "- Estimated maximum: $estimated_total DKK"
  echo "- Approved ceiling: $cost_ceiling DKK"
  echo '- Source: Azure Retail Prices API, DKK consumption rates'
} >"$report_file"

cat "$report_file"

if ((estimated_total > cost_ceiling)); then
  echo "::error::The estimated portfolio deployment cost exceeds $cost_ceiling DKK."
  exit 1
fi

if [[ -n "${GITHUB_ENV:-}" ]]; then
  printf 'PORTFOLIO_ESTIMATED_COST_DKK=%s\n' "$estimated_total" >>"$GITHUB_ENV"
fi

echo "PASS: Estimated temporary deployment cost is $estimated_total DKK."
