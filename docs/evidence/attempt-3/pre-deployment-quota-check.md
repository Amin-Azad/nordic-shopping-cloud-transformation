# Attempt 3 pre-deployment quota check

Date: 10 September 2026

This check was run before Attempt 3 because the first two deployments showed that template validation alone does not prove that a subscription can create the selected Azure services.

The source check was read-only. No Azure resources were created or changed.

## Subscription state

- Subscription offer: Pay-As-You-Go
- Spending limit: Off
- Microsoft.Web: Registered
- Microsoft.Sql: Registered
- Microsoft.KeyVault: Registered
- Microsoft.Network: Registered
- Microsoft.Cdn: Registered
- Microsoft.OperationalInsights: Registered
- Microsoft.Insights: Registered
- Microsoft.Quota: Registered

## Useful regions

| Region | App Service Total Regional VMs | Azure SQL provisioning | Decision |
| --- | ---: | --- | --- |
| Sweden Central | 30 | Available | Candidate |
| West Europe | 30 | Available | Candidate |
| Germany West Central | 0 | Available | Do not use |
| North Europe | 0 | Restricted | Do not use |
| Norway East | 0 | Restricted | Do not use |

Azure SQL also reported one unused subscription free-database allowance at the time of the check.

## Decision

West Europe and Sweden Central are now candidates for the portfolio deployment. This is different from the qualification result after Attempt 2, when the tested region combinations did not meet the App Service quota gate.

This file does **not** claim that Attempt 3 can deploy successfully. The final decision still belongs to `qualification-portfolio.yml`, which checks the exact SQL service objective, App Service SKU quota, Total VMs quota, identity, provider registrations, current Azure state, cost ceiling, provider validation and the exact What-If for the commit being deployed.

The local helper used for future checks is [`scripts/check-quota.sh`](../../../scripts/check-quota.sh).
