# Attempt 3 Pre-Deployment Quota Check

**Date:** 10 September 2026

This check was run before Attempt 3 because the first two deployments showed
that template validation alone does not prove that a subscription can create
the selected Azure services.

The check was read-only. No Azure resources were created or changed.

## Subscription state

* Subscription offer: Pay-As-You-Go
* Spending limit: Off
* Microsoft.Web: Registered
* Microsoft.Sql: Registered
* Microsoft.KeyVault: Registered
* Microsoft.Network: Registered
* Microsoft.Cdn: Registered
* Microsoft.OperationalInsights: Registered
* Microsoft.Insights: Registered
* Microsoft.Quota: Registered

## Region check

| Region               | App Service Total Regional VMs | Azure SQL provisioning | Decision   |
| -------------------- | -----------------------------: | ---------------------- | ---------- |
| Sweden Central       |                             30 | Available              | Candidate  |
| West Europe          |                             30 | Available              | Candidate  |
| Germany West Central |                              0 | Available              | Do not use |
| North Europe         |                              0 | Restricted             | Do not use |
| Norway East          |                              0 | Restricted             | Do not use |

Azure SQL also reported one unused subscription free-database allowance at the
time of the check.

## Result

West Europe and Sweden Central were suitable candidates based on the
pre-deployment quota check.

This result was not treated as proof that deployment would succeed. Final
validation still depended on the deployment workflow, Azure What-If and the
actual Azure deployment result.

This file records the pre-deployment quota state captured before Attempt 3.
The superseded portfolio qualification workflow is preserved in the
`full-design-pipelines` tag. The final successful deployment and runtime
evidence are indexed in the parent Attempt 3 evidence README.

The local helper used for future checks is
[`scripts/check-quota.sh`](../../../scripts/check-quota.sh).
