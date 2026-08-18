# Attempt 2 evidence

The written record is in
[the Attempt 2 report](../../deployment-attempts/deployment-attempt-2-controlled-failure.md).

## Primary records

| Evidence | Result |
|---|---|
| [Guarded deployment run 32123367196](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32123367196) | Failed during resource creation after the preceding gates passed |
| Deployment artifact `dev-deployment-evidence-32123367196` | Uploaded by the deployment workflow |
| [Guarded cleanup run 32124949474](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32124949474) | Passed |
| Cleanup artifact `dev-cleanup-evidence-32124949474` | Uploaded by the cleanup workflow |
| [Correction PR #8](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/pull/8) | Merged |
| [Correction CI run 32127953187](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32127953187) | Passed |
| [Region qualification 32129650123](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32129650123) | Stopped because no tested region qualified |

The workflow runs and retained artifacts are the primary records. The screenshots
below are selected summaries. Terminal screenshots contain only fields extracted
from those artifacts or read-only Azure CLI results.

## Visual record

### 1. Correction CI passed

Bicep formatting, lint, build, parameter compilation and Attempt 2 regression
checks completed successfully.

![Successful infrastructure validation](screenshots/01-ci-validation.png)

### 2. Deployment reached resource creation

OIDC authentication, subscription checks, Provider validation and final What-If
passed before the resource-creation step failed.

![Attempt 2 workflow gates](screenshots/02-attempt-2-gates.png)

### 3. App Service quota failure

The deployment artifact records a regional `Total VMs` limit of zero and one
worker required.

![App Service Total VMs quota error](screenshots/03-app-service-quota-error.png)

### 4. SQL Entra administrator failure

The same artifact records `InvalidParameterValue` for the administrator
`Login` value on both regional SQL servers.

![SQL Entra administrator error](screenshots/04-sql-entra-error.png)

### 5. Partial deployment state

The post-failure evidence captured six resource groups and 23 Azure resources.

![Partial Azure resource state](screenshots/05-partial-resources.png)

### 6. Guarded cleanup passed

The separately confirmed cleanup workflow completed successfully and uploaded
its evidence artifact.

![Successful guarded cleanup](screenshots/06-cleanup-success.png)

### 7. Independent cleanup verification

Read-only Azure CLI checks found no remaining project dev resource groups,
resources, policies, budgets, active or soft-deleted Key Vaults, or tagged
resources.

![Zero-resource verification](screenshots/07-zero-resource-verification.png)

### 8. Region qualification stopped

All seven tested regions reported zero available `Total VMs` capacity for the
subscription, so no region qualified.

![Dev region qualification](screenshots/08-region-qualification.png)

### 9. Corrective changes merged

PR #8 added the quota checks, SQL administrator correction, region qualification
and regression coverage.

![Merged correction PR](screenshots/09-correction-pr.png)

## Capture notes

The capture and redaction criteria are recorded in
[`CAPTURE-CHECKLIST.md`](CAPTURE-CHECKLIST.md). The walkthrough outline is in
[`VIDEO-NOTES.md`](VIDEO-NOTES.md).

Complete raw logs are not copied into this repository because they may contain
account metadata and are less useful than the retained workflow records.
