# Deployment Attempt 3 Evidence

This directory preserves the redacted evidence for the successful minimal-profile
deployment in Sweden Central.

The guarded GitHub Actions deployment ran from `main` on 23 September 2026:

- [Workflow run 35805550250](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/35805550250)
- Commit: `d35c1ad3b2f81e1630bee2e9ed3c4cf15813a960`
- Azure deployment state: `Succeeded`
- Resource inventory: 45 resources across the three minimal-profile resource groups
- Application deployment: successful
- Readiness: passed on attempt 1

## Screenshot evidence

| # | Evidence | Result |
| --- | --- | --- |
| 01 | [Successful deployment workflow](01-deployment-run.png) | GitHub Actions run completed successfully |
| 02 | [Azure What-If summary](02-what-if-summary.png) | Existing live deployment rerun showed 52 modifications, 35 no-change results, 3 unsupported identity-dependent changes and 6 ignored changes |
| 03 | [Resource groups](03-resource-groups.png) | Bootstrap plus the three minimal-profile resource groups were present in Sweden Central |
| 04 | [Private networking inventory](04-private-endpoints.png) | Blob, Key Vault and SQL private endpoints, their NICs, private DNS zones, NSGs and VNet were present |
| 05 | [Key Vault network controls](05-key-vault-network.png) | Public access was disabled |
| 06 | [SQL network controls](06-sql-network.png) | Public network access was disabled |
| 07 | [Readiness response](07-readiness-probe.png) | Application reported `ready`; Key Vault authentication over the private endpoint passed |
| 08 | [Live status page](08-status-page.png) | Deployed App Service reported ready with build metadata |
| 09 | [Availability test](09-availability-test.png) | Last 24 hours: 95.37%, 700 successful and 34 failed tests; current 20-minute window: 100.00%; average duration: 286 ms |
| 10 | [Azure Policy compliance](10-policy-compliance.png) | Settled snapshot: 36% overall, 27 of 76 resources compliant, 49 non-compliant and 14 of 26 policies non-compliant |
| 11 | [Actual cost](11-cost.png) | Main workload resource group actual cost: DKK 6.32 at capture time |
| 12 | `12-cleanup-zero-resources.png` | Pending guarded cleanup and independent zero-resource verification |

The availability failures include the earlier deployment and application-startup
period. The most recent 20-minute window was healthy when the screenshot was
captured.

The policy assignments run in audit/audit-if-not-exists mode. The policy
screenshot records the measured result; it is not presented as full compliance.

The DKK 6.32 cost screenshot is scoped to `rg-nshop-dev-sdc`, not the whole
subscription. It comprised DKK 5.75 SQL Database, DKK 0.54 App Service, DKK 0.03
Key Vault and less than DKK 0.01 Storage at capture time.

## Text evidence

The durable workflow output is under
[github-actions-35805550250](github-actions-35805550250/):

- deployment state and outputs;
- readiness JSON;
- resource inventory and count;
- policy summary from the deployment run;
- run metadata and artifact digest.

## Redaction

Screenshots were reviewed before commit. Personal email, tenant ID, subscription
ID and SQL administrator group object ID are not included in the committed image
set.

## Cleanup gate

Cleanup is intentionally the final step. This evidence set must not be described
as complete until the guarded cleanup succeeds, the three minimal-profile
resource groups are independently verified absent, and item 12 is committed.
