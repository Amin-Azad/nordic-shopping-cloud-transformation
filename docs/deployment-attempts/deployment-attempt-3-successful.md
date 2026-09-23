# Deployment Attempt 3 — Successful Minimal Azure Profile

**Date:** 22 September 2026

**Region:** Sweden Central

**Outcome:** Infrastructure and application deployed and verified through GitHub Actions; availability, policy and cost evidence captured; cleanup deferred

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

The subscription-scope deployment was run locally with Azure CLI from the
minimal-profile feature branch. The deployment workflow now in the repository
was not the execution path for this first successful run, so this record does
not claim a successful GitHub Actions deployment.

Azure recorded the deployment at `2026-09-22T13:24:05Z` with provisioning
state `Succeeded`.

Provisioning state:

```text
Succeeded
```

The post-deployment inventory showed:

- 3 resource groups in Sweden Central;
- 29 resources tagged `deploymentProfile=minimal`;
- one running B1 Linux App Service application;
- one serverless Azure SQL database;
- Key Vault and Storage;
- a VNet, two NSGs, private DNS zones and three private endpoints;
- Log Analytics, Application Insights, a standard availability test, alerts
  and action groups.

The application package was published separately with `az webapp deploy`.
Azure reported `RuntimeSuccessful` with one successful instance and no failed
instances.

PR [#21](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/pull/21)
then integrated the tested minimal profile into `main`. The merged commit is
`a1013ee253317919ca8d02e0401e10f1718f32e4`.

## Runtime verification

The application endpoints were tested directly after publication:

| Endpoint | Result | What it proved |
| --- | --- | --- |
| `/` | HTTP 200 | The Node.js application and status page were being served by App Service |
| `/health/live` | HTTP 200 | The application process was running |
| `/health/ready` | HTTP 200 | The application could authenticate to Key Vault and complete its dependency check |
| `/version` | HTTP 200 | Runtime metadata was available from the deployed application |

The readiness response included:

```json
{
  "status": "ready",
  "checks": {
    "keyVault": {
      "ok": true,
      "detail": "authenticated over private endpoint, probe secret absent",
      "latencyMs": 154
    }
  },
  "service": "nordicshop-api",
  "role": "api",
  "region": "primary",
  "environment": "dev"
}
```

A missing probe secret returns 404 only after authentication and network access
to Key Vault succeed. The application treats that response as ready. Therefore,
this single check exercised the App Service managed identity, the Key Vault RBAC
assignment, private DNS resolution and the private endpoint path together.

## Security posture confirmed

Post-deployment checks confirmed that:

- Key Vault, Azure SQL and Storage public network access were disabled;
- the Key Vault, SQL and Blob private endpoints existed and were approved;
- the App Service used a system-assigned managed identity and HTTPS only;
- the SQL Entra administrator was a security-enabled group rather than the
  guest user configuration rejected during Attempt 2;
- Azure Policy assignments were deployed in audit or audit-if-not-exists mode.

The public App Service endpoint intentionally remained enabled so the status
page and readiness endpoint could be tested without Front Door in the minimal
profile. The protected data services remained private.

## Monitoring and governance

The deployment created Log Analytics, Application Insights, a three-location
standard availability test for `/health/ready`, its availability alert, three
action groups and service/resource health alerts. It also created 26 policy
assignments covering location, tags, identity, TLS, basic authentication and
data-service network settings.

After Azure collected data, the standard availability test showed 95.37% over
the previous 24 hours, with 700 successful and 34 failed tests and an average
duration of 286 ms. The current 20-minute window was 100.00%. The failed tests
include the earlier deployment and application-startup period.

The settled Azure Policy snapshot showed 36% overall compliance: 27 of 76
resources compliant, 49 non-compliant and 14 of 26 policies non-compliant. The
assignments run in audit or audit-if-not-exists mode, so this is recorded as an
observed governance result rather than a claim of full compliance.

## Cost

The template deployed a subscription budget and used the low-cost minimal
profile. At capture time, Azure Cost Analysis showed DKK 6.32 for the main
workload resource group, `rg-nshop-dev-sdc`: DKK 5.75 SQL Database, DKK 0.54
App Service, DKK 0.03 Key Vault and less than DKK 0.01 Storage. This is a
resource-group-scoped observation, not a whole-subscription cost claim.

## Cleanup status

The repository contains a guarded minimal cleanup workflow that deletes only
the three minimal-profile resource groups, purges the recoverable Key Vault when
permitted and fails if tagged resources remain.

Cleanup was explicitly deferred on 23 September 2026, so the live resources
remain running. No cleanup run or independent zero-resource result is claimed.
Attempt 3 must not be described as cleaned up until those two pieces of evidence
exist.

## GitHub Actions verification — 23 September 2026

The guarded workflow was then run from `main` at commit
`d35c1ad3b2f81e1630bee2e9ed3c4cf15813a960`.

- Run: [Minimal profile deployment #4](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/35805550250)
- Job: [Deploy and verify the minimal profile](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/35805550250/job/107005437786)
- Result: success
- Deployment name: `minimal-35805550250`
- Azure deployment state: `Succeeded`
- Resource inventory: 45 resources across the three minimal-profile resource groups
- Application publish: successful
- Readiness: passed on attempt 1
- Evidence artifact: `minimal-deployment-evidence-35805550250`
- Artifact digest: `sha256:d3058ac6d44698d22523744157ce6f4b07b8db1989af21bf029fde8372e09725`

The readiness response confirmed that the application was running commit
`d35c1ad3b2f81e1630bee2e9ed3c4cf15813a960` and authenticated to Key Vault
over the private endpoint.

The workflow artifact is preserved in GitHub Actions, and the durable evidence
files are stored under `docs/evidence/attempt-3/github-actions-35805550250/`.

## Evidence capture status

The redacted screenshot and text evidence set is indexed at
[`docs/evidence/attempt-3/README.md`](../evidence/attempt-3/README.md). It includes
the successful workflow, What-If summary, resource inventory, private networking,
network restrictions, readiness, live status, availability, settled policy and
actual cost observations.

The only missing evidence item is the guarded cleanup run and independent
zero-resource verification. Cleanup was deferred, so item 12 remains open.

## What I would do next

When cleanup is authorized, run the guarded minimal cleanup workflow from
`main`, preserve its artifact, independently verify that no `rg-nshop-dev*`
resources remain and commit `12-cleanup-zero-resources.png`.
