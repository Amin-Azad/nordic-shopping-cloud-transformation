# Deployment Attempt 3 — Successful Minimal Azure Profile

## Summary

The third guarded Azure deployment attempt succeeded using a reduced single-region deployment profile designed to fit the subscription limits while still proving the platform architecture on real Azure resources.

The full multi-region architecture remains the target design. This minimal profile was introduced to provide real deployment evidence without removing the original architecture.

## Why Attempt 3 was different

The earlier deployment attempts exposed two main blockers:

- App Service regional quota limitations
- Azure SQL deployment and Entra administrator issues

Attempt 3 introduced a separate minimal deployment path instead of weakening the full target architecture.

The minimal profile uses:

- Sweden Central
- one Linux App Service plan
- one Node.js web application
- Azure SQL serverless database
- Key Vault
- Storage Account
- VNet integration
- private endpoints
- private DNS
- managed identity and RBAC
- Log Analytics and Application Insights
- Azure Monitor alerts
- Azure Policy in audit mode
- subscription budget controls

## Issues found during validation

Before deployment, several issues were discovered and corrected.

### Bicep module output issue

The first build of `main.minimal.bicep` failed with BCP182 because a parent-level array comprehension attempted to use deployment-time module outputs.

The fix moved the web app ID array into the regional platform module as an explicit output.

### SQL and Key Vault public network access

The first Azure What-If showed that SQL and Key Vault public network access were still enabled for the dev environment.

The shared regional module was updated with optional minimal-profile overrides so that:

- SQL public network access is disabled
- Key Vault public network access is disabled
- the existing full dev architecture retains its previous behavior

### Autoscale compatibility

Autoscale is now only deployed when enabled. This avoids creating Azure Monitor autoscale settings against the B1 App Service plan used by the minimal profile.

### SQL serverless configuration

The minimal profile uses:

- SKU: `GP_S_Gen5_1`
- capacity: 1
- auto-pause delay: 60 minutes
- local backup storage redundancy
- zone redundancy disabled

## Pre-deployment validation

The following checks passed before deployment:

- original `main.bicep` compiled successfully
- `main.minimal.bicep` compiled successfully
- Bicep wiring validation passed
- compiled-template security validation passed
- `GP_S_Gen5_1` was available in Sweden Central
- B1 Linux App Service was available in Sweden Central
- SQL Entra administrator group was created and verified
- Azure What-If completed successfully

The What-If reported:

- 87 resources to create
- 3 unsupported changes

The unsupported changes were managed-identity RBAC assignments whose final IDs depended on the App Service identity being created during deployment.

## Deployment result

The subscription deployment completed successfully.

Provisioning state:

```text
Succeeded
