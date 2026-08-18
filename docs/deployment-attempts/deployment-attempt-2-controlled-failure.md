# Guarded dev deployment attempt 2

Date: 18 August 2026  
Outcome: stopped during resource creation; cleanup completed

## Scope

This was a temporary development deployment from commit
[`4b6b3d6`](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/commit/4b6b3d60340b65d9be4e91b437bbf34b45f4e8ee).
It was not a production deployment.

The guarded workflow required a manual dispatch, the expected confirmation
value, the approved commit, GitHub environment controls and Azure OIDC
authentication.

## What passed

The [deployment run](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32123367196)
records successful completion of:

- manual request validation;
- pinned Bicep installation;
- cost and safety policy checks;
- deployment-location resolution;
- Azure sign-in through OIDC;
- subscription and tenant verification;
- the readiness check then in use;
- Azure Provider validation; and
- the final pre-deployment What-If.

Resource creation then started and the workflow collected partial state and
uploaded an evidence artifact after the deployment step failed.

## Failure

Two independent deployment errors were confirmed.

1. Azure App Service returned `SubscriptionIsOverQuotaForSku`. The selected
   regions exposed quota for the requested Premium v4 SKU, but the subscription's
   separate regional `Total VMs` limit was zero.
2. Both Azure SQL logical servers rejected the Microsoft Entra administrator
   `Login` value with `InvalidParameterValue`.

The original readiness script checked SKU-specific availability but not the
separate `Total VMs` quota. It therefore allowed the deployment to proceed
despite the effective App Service capacity being zero.

## Recovery

No retry was attempted.

The [guarded cleanup run](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32124949474)
completed successfully against the same commit. Its workflow evidence shows the
manual confirmation, OIDC sign-in, subscription verification, cleanup script,
summary generation and artifact upload all passed.

Independent CLI checks performed after cleanup returned no remaining Nordic
Shopping dev resource groups, resources, policy assignments, budgets, active or
soft-deleted Key Vaults, or tagged dev resources.

## Correction

[PR #8](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/pull/8)
made the following changes:

- the readiness check now validates both SKU quota and `Total VMs`;
- a read-only region-qualification workflow checks SQL and App Service
  compatibility together;
- the SQL Entra administrator is declared on the SQL server resource;
- regression tests cover both Attempt 2 failure modes; and
- the guarded What-If includes qualification and Provider validation.

The [correction CI run](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32127953187)
passed Bicep formatting, linting, build, environment-parameter compilation and
the new regression checks.

The subsequent [region-qualification run](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32129650123)
authenticated successfully but found no compatible pair among the seven tested
regions. Every tested region reported `Total VMs = 0` for this subscription.
The workflow therefore failed closed, as designed.

## Current boundary

Development and production are not deployed. No claim in this repository should
be read as evidence of a completed production deployment.

The Bicep implementation, validation pipeline, OIDC authentication, guarded
deployment controls, partial resource creation, failure diagnosis, regression
checks and cleanup are evidenced. A further deployment requires a subscription
and region combination that passes the qualification gate.
