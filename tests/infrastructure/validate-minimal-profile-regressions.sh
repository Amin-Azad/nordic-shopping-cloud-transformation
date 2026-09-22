#!/usr/bin/env bash
set -euo pipefail

MINIMAL="infra/bicep/main.minimal.bicep"
REGIONAL="infra/bicep/orchestration/regional-platform.bicep"

grep -q 'forcePrivateSql: true' "$MINIMAL" || {
  echo "FAIL: minimal profile must force SQL private access"
  exit 1
}

grep -q 'forcePrivateKeyVault: true' "$MINIMAL" || {
  echo "FAIL: minimal profile must force Key Vault private access"
  exit 1
}

grep -q "forcePrivateSql ? 'Disabled' : 'Enabled'" "$REGIONAL" || {
  echo "FAIL: regional platform SQL private override is missing"
  exit 1
}

grep -q "forcePrivateKeyVault ? 'Disabled' : 'Enabled'" "$REGIONAL" || {
  echo "FAIL: regional platform Key Vault private override is missing"
  exit 1
}

echo "PASS: minimal profile private-network regressions are guarded."
