# Nordic Shopping Cloud Transformation

[![Infrastructure validation](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/workflows/infrastructure-validation.yml/badge.svg)](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/workflows/infrastructure-validation.yml)
[![Azure](https://img.shields.io/badge/Cloud-Microsoft%20Azure-0078D4?logo=microsoftazure)](https://azure.microsoft.com/)
[![Bicep](https://img.shields.io/badge/IaC-Bicep-0078D4)](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=githubactions)](https://github.com/features/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

End-to-end Azure cloud transformation case study for a fictional Copenhagen
e-commerce business.

I designed the target Azure platform, built the infrastructure with modular
Bicep, added GitHub Actions delivery controls, tested the design against a real
Azure subscription and preserved evidence from both failed and successful
deployment attempts.

> **Current status:** a reduced single-region profile was successfully deployed
> and verified in Sweden Central through GitHub Actions. Application readiness,
> managed identity, private Key Vault access, monitoring, Azure Policy and actual
> cost evidence were captured. The full multi-region production design has not
> been deployed.

## Architecture

[![Nordic Shopping target architecture](architecture/diagrams/exports/01-architecture-overview.png)](architecture/diagrams/exports/01-architecture-overview.png)

The production design uses **West Europe** as the primary region and
**Sweden Central** as the recovery region.

Main components:

* Azure Front Door and WAF
* Azure App Service
* Azure SQL Database
* Azure Storage
* Azure Key Vault
* VNets, NSGs, private endpoints and private DNS
* Microsoft Entra ID and Azure RBAC
* managed identities
* Log Analytics and Application Insights
* Azure Monitor alerts
* Azure Policy and budgets
* GitHub Actions with OIDC
* modular subscription-scope Bicep

The target design separates public application delivery from private data
services and avoids stored Azure credentials for CI/CD and application access.

The complete design, deployed scope and major decisions are documented in
[Architecture](docs/architecture.md).

## What I built

| Area                   | Implementation                                                     |
| ---------------------- | ------------------------------------------------------------------ |
| Infrastructure as code | Modular subscription-scope Bicep                                   |
| Compute                | Azure App Service plans and application workloads                  |
| Data                   | Azure SQL Database and Storage                                     |
| Identity               | Entra groups, managed identities, RBAC and GitHub OIDC             |
| Networking             | VNets, NSGs, private endpoints and private DNS                     |
| Secrets                | Azure Key Vault with RBAC                                          |
| Edge                   | Azure Front Door and WAF in the production target                  |
| Monitoring             | Log Analytics, Application Insights, availability tests and alerts |
| Governance             | Azure Policy, tags, budgets and environment controls               |
| Delivery               | Validation, What-If, guarded deployment and cleanup workflows      |
| Recovery               | Multi-region target architecture and SQL recovery design           |

## Infrastructure as code

The full target architecture starts from:

[`infra/bicep/main.bicep`](infra/bicep/main.bicep)

The deployed validation profile starts from:

[`infra/bicep/main.minimal.bicep`](infra/bicep/main.minimal.bicep)

```text
infra/bicep/
├── bootstrap/
├── environments/
│   ├── dev/
│   ├── minimal/
│   └── prod/
├── modules/
│   ├── ai/
│   ├── compute/
│   ├── data/
│   ├── governance/
│   ├── identity/
│   ├── monitoring/
│   ├── networking/
│   └── security/
├── orchestration/
├── main.bicep
└── main.minimal.bicep
```

The minimal profile reuses the same platform modules but deploys one region,
one application and smaller Azure service sizes. It exists to provide real
deployment evidence without weakening the production target architecture.

## CI/CD and deployment safety

The remaining GitHub Actions workflows have clear responsibilities:

| Workflow                                                                     | Purpose                                                  |
| ---------------------------------------------------------------------------- | -------------------------------------------------------- |
| [Infrastructure validation](.github/workflows/infrastructure-validation.yml) | Compile and validate Bicep and run infrastructure checks |
| [Dev What-If](.github/workflows/dev-what-if.yml)                             | Preview the full development design against Azure        |
| [Minimal validation](.github/workflows/minimal-validate.yml)                 | Validate the deployable minimal profile                  |
| [Minimal deployment](.github/workflows/minimal-deploy.yml)                   | Guarded Azure deployment and runtime verification        |
| [Minimal cleanup](.github/workflows/minimal-cleanup.yml)                     | Controlled removal of the temporary environment          |

GitHub Actions authenticates to Azure through **OIDC workload identity
federation**, so the repository does not require a stored Azure client secret.

Deployment and cleanup are separate guarded operations.

## Deployment evidence

### Attempt 1

The first deployment reached Azure and exposed issues that static Bicep
validation had not detected, including service configuration, dependency and
subscription-capacity problems.

The partial deployment was investigated and cleaned up before the infrastructure
was corrected.

[Attempt 1 record](docs/deployments/attempt-1.md)

### Attempt 2

The second controlled deployment passed the earlier validation gates but stopped
during Azure resource creation.

The two main blockers were:

* App Service `Total Regional VMs` quota;
* Azure SQL Entra administrator configuration.

The guarded cleanup completed successfully and an independent Azure CLI check
confirmed that the development resources were removed.

[Attempt 2 record](docs/deployments/attempt-2.md)
[Attempt 2 evidence](docs/evidence/attempt-2/README.md)

### Attempt 3 — successful

Attempt 3 used the minimal profile in **Sweden Central**.

GitHub Actions run
[`35805550250`](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/35805550250)
completed successfully.

Verified results:

| Check                                | Result                                                    |
| ------------------------------------ | --------------------------------------------------------- |
| Azure deployment                     | `Succeeded`                                               |
| Resource inventory                   | 45 resources across three minimal-profile resource groups |
| Application publication              | Successful                                                |
| Readiness                            | Passed on attempt 1                                       |
| Application endpoints                | HTTP 200                                                  |
| Key Vault dependency                 | `keyVault.ok: true`                                       |
| SQL public access                    | Disabled                                                  |
| Key Vault public access              | Disabled                                                  |
| Private endpoints                    | Deployed                                                  |
| 24-hour availability snapshot        | 95.37%                                                    |
| Latest 20-minute availability window | 100%                                                      |
| Azure Policy snapshot                | 36% compliance in audit mode                              |
| Observed workload cost               | DKK 6.32                                                  |

The Key Vault readiness check exercised the application managed identity, Azure
RBAC, private DNS and private endpoint path together.

The 24-hour availability result includes deployment/startup failures. The latest
20-minute window was 100% when the evidence was captured.

The Azure Policy result is intentionally reported as observed audit-mode
compliance rather than being presented as full compliance.

[Attempt 3 record](docs/deployments/attempt-3.md)
[Attempt 3 evidence](docs/evidence/attempt-3/README.md)

## Security approach

The project applies several controls that I would expect in a production-oriented
Azure platform:

* managed identities instead of application credentials;
* GitHub Actions OIDC instead of a stored Azure client secret;
* Azure RBAC;
* Entra group-based administration;
* SQL and Key Vault public network access disabled in the deployed profile;
* private endpoints and private DNS;
* HTTPS-only application access;
* Azure Policy in audit mode;
* monitoring and operational alerts;
* environment-specific protection settings.

The detailed implementation and remaining risks are documented in
[Security](docs/security.md).

## Cost

The full production architecture is a planning design and has not been deployed
at production scale.

The estimated production planning baseline is approximately **DKK 15,000 per
month**, with **DKK 16,500** used as an upper normal-month planning boundary.

The successful minimal deployment also produced real Azure Cost Analysis
evidence.

At capture time, the main workload resource group had accumulated:

| Service      |      Observed cost |
| ------------ | -----------------: |
| SQL Database |           DKK 5.75 |
| App Service  |           DKK 0.54 |
| Key Vault    |           DKK 0.03 |
| Storage      | Less than DKK 0.01 |
| **Total**    |       **DKK 6.32** |

This is a time-bound deployment observation, not a monthly forecast or
whole-subscription total.

See [Cost](docs/cost.md) for the assumptions and cost boundaries.

## Validation

The current infrastructure has been checked with:

* Bicep wiring validation;
* compilation of the full `main.bicep`;
* compilation of `main.minimal.bicep`;
* compilation of dev, prod and minimal parameter files;
* compiled-template security assertions;
* minimal-profile private-network regression tests;
* Azure What-If;
* real Azure deployment;
* application readiness checks.

The compiled minimal-template security test currently reports:

* 10 assertions passed;
* 0 failed;
* SQL public network access unresolved statically because the value is computed
  at deployment time.

The real Attempt 3 deployment independently confirmed that SQL public network
access was disabled.

## What this project demonstrates

This project demonstrates practical experience with:

* Azure architecture and service selection;
* Bicep module design and composition;
* Azure App Service and Azure SQL;
* private networking;
* Microsoft Entra ID and managed identities;
* Azure RBAC;
* GitHub Actions and OIDC;
* Azure Monitor and Application Insights;
* Azure Policy and cost controls;
* deployment troubleshooting;
* cloud quota and regional-capacity constraints;
* controlled cleanup;
* documenting evidence instead of claiming unverified success.

## Scope boundary

This repository is a portfolio case study, not a live production environment.

Successfully proven:

* infrastructure validation;
* GitHub Actions OIDC;
* real Azure deployment;
* application publication and health checks;
* managed identity access to Key Vault;
* private access to protected services;
* monitoring and availability testing;
* Azure Policy observation;
* real deployment cost capture;
* cleanup and independent verification for Attempt 2.

Not claimed as proven:

* production deployment of the full multi-region design;
* production load testing;
* live regional disaster-recovery failover;
* Attempt 3 zero-resource cleanup until its final cleanup evidence is recorded.

## Documentation

| Document                                                | Purpose                                                  |
| ------------------------------------------------------- | -------------------------------------------------------- |
| [Architecture](docs/architecture.md)                    | Full design, deployed scope and key decisions            |
| [Security](docs/security.md)                            | Identity, networking, secrets, policy and residual risks |
| [Cost](docs/cost.md)                                    | Forecast assumptions and observed deployment cost        |
| [Attempt 1](docs/deployments/attempt-1.md)              | First failure, diagnosis and corrections                 |
| [Attempt 2](docs/deployments/attempt-2.md)              | Controlled failure, quota findings and cleanup           |
| [Attempt 3](docs/deployments/attempt-3.md)              | Successful deployment and verification                   |
| [Attempt 3 evidence](docs/evidence/attempt-3/README.md) | Screenshots and workflow output                          |

## Architecture diagrams

| Diagram                    | Preview                                                                | Editable source                                                              |
| -------------------------- | ---------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Architecture overview      | [PNG](architecture/diagrams/exports/01-architecture-overview.png)      | [Draw.io](architecture/diagrams/source/01-architecture-overview.drawio)      |
| Identity and traffic flow  | [PNG](architecture/diagrams/exports/02-identity-and-traffic-flow.png)  | [Draw.io](architecture/diagrams/source/02-identity-and-traffic-flow.drawio)  |
| Regional network and data  | [PNG](architecture/diagrams/exports/03-regional-network-and-data.png)  | [Draw.io](architecture/diagrams/source/03-regional-network-and-data.drawio)  |
| Deployment and operations  | [PNG](architecture/diagrams/exports/04-deployment-and-operations.png)  | [Draw.io](architecture/diagrams/source/04-deployment-and-operations.drawio)  |
| Full security architecture | [PNG](architecture/diagrams/exports/06-full-security-architecture.png) | [Draw.io](architecture/diagrams/source/06-full-security-architecture.drawio) |

## Quick review

If you only have a few minutes:

1. View the [architecture overview](architecture/diagrams/exports/01-architecture-overview.png).
2. Read [Architecture](docs/architecture.md).
3. Review [`main.bicep`](infra/bicep/main.bicep) and [`main.minimal.bicep`](infra/bicep/main.minimal.bicep).
4. Review the [successful Attempt 3 record](docs/deployments/attempt-3.md).
5. Open the [Attempt 3 evidence](docs/evidence/attempt-3/README.md).

## Security

Do not commit credentials, connection strings, certificates, access tokens or
environment-specific secrets.

See [SECURITY.md](SECURITY.md).

## Disclaimer

Nordic Shopping is a fictional company created for this portfolio case study.
The architecture and engineering decisions are designed to represent a realistic
Azure migration scenario, but the repository does not represent a production
system operated by a real organization.

## License

This project is available under the [MIT License](LICENSE).
