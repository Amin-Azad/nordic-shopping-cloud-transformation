# Deployment Attempt 3 — Successful Minimal Profile

**Date:** 23 September 2026
**Region:** Sweden Central
**Outcome:** Successful deployment, verification and cleanup; zero active resources independently confirmed.

## Deployment result

Attempt 3 used the minimal Azure deployment profile to prove the platform on real Azure resources without changing the full target architecture.

The deployment was executed through GitHub Actions.

* GitHub Actions run: `35805550250`
* Region: Sweden Central
* Deployment state: `Succeeded`
* Deployment name: `minimal-35805550250`
* Resources: 45 across three minimal-profile resource groups
* Application publication: successful
* Readiness: passed on attempt 1

The deployed profile included App Service, Azure SQL, Key Vault, Storage, private networking, managed identity, monitoring, policy and budget controls.

The minimal profile was used because the earlier full-profile attempts were blocked by subscription quota and SQL administrator configuration issues.

## Verification

The deployed application passed its runtime checks.

| Check                   | Result              |
| ----------------------- | ------------------- |
| Application publication | Successful          |
| `/`                     | HTTP 200            |
| `/health/live`          | HTTP 200            |
| `/health/ready`         | HTTP 200            |
| `/version`              | HTTP 200            |
| Readiness               | Passed on attempt 1 |
| Key Vault check         | Passed              |

The readiness response confirmed:

```json
{
  "keyVault": {
    "ok": true
  }
}
```

This confirmed that the application could authenticate to Key Vault using its managed identity through the private networking path.

## Security posture confirmed

Post-deployment checks confirmed that:

* Azure SQL public network access was disabled;
* Key Vault public network access was disabled;
* private endpoints were deployed;
* SQL, Key Vault and Blob private connectivity was present;
* App Service used a system-assigned managed identity;
* HTTPS-only access was enabled;
* SQL used an Entra security group for administration;
* Azure Policy assignments were running in audit mode.

The App Service remained publicly reachable for application and readiness testing. The protected data services remained private.

## Monitoring and governance

The deployment included:

* Log Analytics;
* Application Insights;
* Azure availability testing;
* alerts and action groups;
* Azure Policy assignments.

The observed availability result was:

| Measurement                | Result |
| -------------------------- | -----: |
| Availability over 24 hours | 95.37% |
| Successful tests           |    700 |
| Failed tests               |     34 |
| Latest 20-minute window    |   100% |
| Average duration           | 286 ms |

The failed tests included the earlier deployment and application-startup period.

The settled Azure Policy snapshot showed:

* 36% overall compliance;
* 27 of 76 resources compliant;
* 49 resources non-compliant;
* 14 of 26 policies reporting non-compliance.

The policies were running in audit or audit-if-not-exists mode, so this is recorded as an observed governance result rather than full compliance.

## Cost

Azure Cost Analysis showed DKK 6.32 for the main workload resource group,
`rg-nshop-dev-sdc`, at the evidence-capture point.

| Service      |      Observed cost |
| ------------ | -----------------: |
| SQL Database |           DKK 5.75 |
| App Service  |           DKK 0.54 |
| Key Vault    |           DKK 0.03 |
| Storage      | Less than DKK 0.01 |

This is a time-bound resource-group observation, not a monthly forecast or whole-subscription total.

## Cleanup

The guarded minimal cleanup workflow completed successfully after evidence
collection.

GitHub Actions cleanup run `35900828038` deleted the three minimal-profile
resource groups:

* `rg-nshop-dev-sdc`;
* `rg-nshop-dev-network`;
* `rg-nshop-dev-monitor`.

The workflow's final verification reported:

```text
Remaining resources: 0
```

A separate Azure CLI verification also returned:

* 0 remaining `rg-nshop-dev*` resource groups;
* 0 remaining resources in `rg-nshop-dev*` resource groups;
* 0 matching soft-deleted `kv-nshop-dev-sdc*` Key Vault records.

The cleanup screenshot is preserved at
[`docs/evidence/attempt-3/12-cleanup-zero-resources.png`](../evidence/attempt-3/12-cleanup-zero-resources.png).

The durable workflow verification is preserved at
[`docs/evidence/attempt-3/cleanup/zero-resource-verification.txt`](../evidence/attempt-3/cleanup/zero-resource-verification.txt).

That file records the cleanup workflow result:

```text
Remaining resources: 0
```

## Lessons learned

Attempt 3 confirmed several practical lessons.

Subscription quota and regional availability must be checked before deployment. Successful Bicep validation alone does not prove that Azure can create the requested resources.

Using a separate minimal deployment profile was better than weakening the full target architecture just to make a deployment succeed.

Azure What-If helped identify configuration problems before deployment, including SQL and Key Vault public network settings.

Runtime verification was also important. A successful Azure deployment does not prove that the application, identity and private networking work together.

The Key Vault readiness check gave stronger evidence because it tested managed identity, RBAC, private DNS and the private endpoint path from the application.

Cleanup was treated as part of the deployment lifecycle and was only marked
complete after the guarded workflow and an independent Azure verification both
confirmed zero remaining active resources.
