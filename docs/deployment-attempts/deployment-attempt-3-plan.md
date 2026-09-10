# Guarded dev deployment attempt 3 — plan

Date prepared: 10 September 2026
Status: Ready for qualification, not yet deployed

## Goal

Attempt 3 is the final portfolio deployment cycle for the development environment. The aim is not only to create Azure resources. I want to prove the complete delivery path, keep the evidence, and remove the environment cleanly afterwards.

## Why another attempt is justified

Attempts 1 and 2 were stopped by real Azure conditions and were cleaned up afterwards. The second attempt exposed two remaining blockers: App Service Total Regional VMs quota and the SQL Entra administrator payload.

Since then:

- the SQL server module uses an Entra security group with `principalType: Group` and Entra-only authentication;
- quota and region qualification checks cover both SKU-specific workers and Total Regional VMs;
- the subscription is Pay-As-You-Go with no spending limit;
- a read-only check on 10 September 2026 found App Service capacity and Azure SQL availability in West Europe and Sweden Central.

The new quota result is only a reason to run the qualification gate again. It is not treated as proof that deployment will succeed.

## Deployment profile

Attempt 3 uses the existing `portfolio` development profile rather than changing the production target design.

The portfolio profile keeps the same architecture and security controls where practical, while reducing cost and capacity for a short-lived validation deployment:

- one App Service worker per regional plan;
- no zone redundancy;
- no staging slots;
- autoscale disabled;
- Azure AI Services disabled;
- development retention and protection settings;
- guarded cost ceiling and short deployment lifetime.

The qualification workflow selects the compatible regions and App Service SKU for the current subscription. The production design remains West Europe primary with Sweden Central recovery unless the architecture documents are changed separately.

## Required order

1. Infrastructure validation must pass on the exact commit.
2. `Portfolio qualification` must pass and produce its evidence artifact.
3. Review the selected regions, SKU, cost estimate and What-If.
4. Trigger `Portfolio deployment` from the same `main` commit with the successful qualification run ID.
5. Approve the protected `dev` environment and use the exact deployment confirmation.
6. Capture the successful or partial deployment evidence produced by the workflow.
7. Verify the deployed Azure resources, identity, networking, SQL, Key Vault and monitoring configuration.
8. Capture the final screenshots and machine-readable evidence before cleanup.
9. Trigger the guarded portfolio cleanup workflow.
10. Independently verify that no Nordic Shopping development resources, policies, budgets or recoverable Key Vault remnants remain.
11. Replace this plan with the final Attempt 3 result and update the README only with claims supported by run IDs or saved evidence.

## Evidence required before I call Attempt 3 successful

| Check | Required evidence |
| --- | --- |
| Infrastructure validation | successful GitHub Actions run |
| Portfolio qualification | successful run and downloaded qualification artifact |
| Provider validation | included in qualification evidence |
| What-If | exact qualification What-If with no unexpected deletion |
| Deployment | successful guarded deployment run |
| Azure resources | resource inventory from the deployment artifact and CLI verification |
| Identity and security | managed identities, Entra SQL administrator, RBAC and private-access configuration verified |
| Monitoring | Log Analytics / Application Insights resources and diagnostic settings verified |
| Cleanup | successful guarded cleanup run |
| Zero-resource check | independent verification after cleanup |

## Failure rule

If qualification or deployment fails, I will not patch resources manually in Azure and call it successful. I will preserve the evidence, identify the terminal Azure error, fix the source or guardrail, validate the change, and only then decide whether another controlled run is justified.

## Portfolio claim boundary

Until the deployment and verification evidence exists, the repository will continue to say that a complete live development environment has **not** been proven. Production deployment and live disaster-recovery execution remain out of scope for this attempt.
