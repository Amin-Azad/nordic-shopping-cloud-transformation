# Attempt 2 Evidence

The written record is in
[the Attempt 2 report](../../deployments/attempt-2.md).

## Primary records

| Evidence                                                                                                                         | Result                                                           |
| -------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| [Guarded deployment run 32123367196](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32123367196) | Failed during resource creation after the preceding gates passed |
| Deployment artifact `dev-deployment-evidence-32123367196`                                                                        | Uploaded by the deployment workflow                              |
| [Guarded cleanup run 32124949474](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32124949474)    | Passed                                                           |
| Cleanup artifact `dev-cleanup-evidence-32124949474`                                                                              | Uploaded by the cleanup workflow                                 |
| [Correction PR #8](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/pull/8)                                     | Merged                                                           |
| [Correction CI run 32127953187](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32127953187)      | Passed                                                           |
| [Region qualification 32129650123](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32129650123)   | Stopped because no tested region qualified                       |

## Summary

Attempt 2 reached Azure resource creation after the validation gates passed.

The deployment then stopped on two Azure issues:

* App Service regional `Total VMs` quota was zero;
* Azure SQL rejected the Entra administrator configuration.

The partial deployment created six resource groups and 23 Azure resources.

A guarded cleanup workflow then completed successfully. Independent Azure CLI
checks confirmed that no project development resources, policies, budgets,
active Key Vaults, soft-deleted Key Vaults or tagged resources remained.

The correction work was merged through PR #8 and added improved quota checks,
SQL administrator handling, region qualification and regression coverage.

The linked workflow runs and retained artifacts are the primary evidence.
Selected redacted screenshots are stored in this directory.
