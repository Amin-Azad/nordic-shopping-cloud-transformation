# Nordic Shopping Cloud Transformation

[![Infrastructure validation](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/workflows/infrastructure-validation.yml/badge.svg)](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/workflows/infrastructure-validation.yml)
[![Azure](https://img.shields.io/badge/Cloud-Microsoft%20Azure-0078D4?logo=microsoftazure)](https://azure.microsoft.com/)
[![Bicep](https://img.shields.io/badge/IaC-Bicep-0078D4)](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=githubactions)](https://github.com/features/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

I built this project as an end-to-end Azure cloud transformation case study for Nordic Shopping, a fictional e-commerce marketplace based in Copenhagen.

The project starts with a small on-premises environment and follows the path I would use for a real migration: understand the business, define requirements, design the target platform, estimate cost, assess security risks, build the infrastructure as code, add deployment controls, test the design and document what happened.

This is a production-oriented design and implementation project. It is not presented as a live production system.

> **Current status: deployed and verified through GitHub Actions.** On 23
> September 2026, the guarded minimal-profile workflow completed successfully in
> Sweden Central. Readiness authenticated to Key Vault over a private endpoint,
> and redacted deployment, availability, policy and actual-cost evidence is
> preserved in the repository. Cleanup was deferred, so the temporary Azure
> resources remain running and zero-resource verification is still pending.

## The scenario

Nordic Shopping has approximately 35 employees, 40,000 customers, 150 vendors and 600 orders per day. The existing environment has limited resilience, manual operations and no tested regional recovery capability.

For planning, I used a three-year target of 250,000 customers, 800 vendors and around 5,000 daily orders. The initial Azure sizing is a planning baseline, not a load-tested capacity claim.

The production target uses West Europe as the primary region and Sweden Central as the recovery region. The estimated planning baseline is approximately DKK 15,000 per month, with DKK 16,500 used as the upper boundary for a normal month.

## Architecture

[![Nordic Shopping target architecture](architecture/diagrams/exports/01-architecture-overview.png)](architecture/diagrams/exports/01-architecture-overview.png)

Public traffic is designed to enter through Azure Front Door and Web Application Firewall. Separate App Service workloads are defined for the customer site, vendor portal, administration portal and API. Azure SQL Database, Storage and Key Vault use private connectivity in the target design, and managed identities are used for service access.

The production architecture is multi-region. For short-lived live validation,
the repository also contains a separate single-region `minimal` entry point
that reuses the shared modules at lower capacity. That is the profile that
deployed successfully.

### Main design choices

- subscription-scope modular Bicep;
- West Europe primary and Sweden Central recovery design;
- Azure Front Door and WAF at the edge;
- App Service for the application workloads;
- Azure SQL Database and Storage for data;
- Key Vault for secrets and protected configuration;
- VNet integration, private endpoints and private DNS;
- Microsoft Entra security groups and Azure RBAC;
- managed identities instead of stored application credentials;
- GitHub Actions OIDC instead of an Azure client secret;
- Log Analytics, Application Insights, alerts and workbook monitoring;
- Azure Policy, tags, budgets and environment-specific controls;
- guarded deployment and guarded cleanup workflows.

More detail is in the [target architecture](docs/architecture/04-target-architecture.md) and [architecture decisions](docs/architecture/10-architecture-decisions.md).

## What I implemented

| Area | Implementation |
| --- | --- |
| Business | Business case, requirements, current-state assessment and migration roadmap |
| Architecture | Multi-region Azure target design and nine editable diagrams |
| Infrastructure as code | Subscription-scope modular Bicep with dev, portfolio and production parameters |
| Compute | App Service plans and separate web application workloads |
| Data | Azure SQL Database, Storage, SQL failover design and private connectivity |
| Identity | Entra groups, managed identities, Azure RBAC and GitHub workload identity federation |
| Network security | VNets, delegated subnets, NSGs, private endpoints, private DNS, Front Door and WAF |
| Secrets | Azure Key Vault with RBAC and environment-specific protection settings |
| Monitoring | Log Analytics, Application Insights, diagnostic settings, alerts, action groups and workbook |
| Governance | Naming, tagging, Azure Policy, budgets, locks and environment controls |
| Delivery | Validation, qualification, What-If, guarded deployment and cleanup workflows |
| Recovery | Warm-standby design, SQL failover planning and documented recovery procedures |

## Infrastructure as code

The entry point is [`infra/bicep/main.bicep`](infra/bicep/main.bicep).

```text
infra/bicep/
├── bootstrap/          GitHub/Azure deployment identity support
├── environments/
│   ├── dev/            Development parameters
│   ├── portfolio/      Short-lived live validation profile
│   └── prod/           Production target parameters
├── modules/
│   ├── ai/
│   ├── compute/
│   ├── data/
│   ├── governance/
│   ├── identity/
│   ├── monitoring/
│   ├── networking/
│   └── security/
├── orchestration/      Regional and global composition
└── main.bicep          Subscription-scope entry point
```

The same modules are reused across the environment profiles. The portfolio profile lowers capacity and disables optional cost-heavy features; it does not replace the production architecture.

## CI/CD and deployment safety

The deployment path is intentionally stricter than a simple `az deployment create` command.

### Core development workflows

| Workflow | Purpose |
| --- | --- |
| [Infrastructure validation](.github/workflows/infrastructure-validation.yml) | Format, lint, build, compile all environment profiles and run regression checks |
| [Dev What-If](.github/workflows/dev-what-if.yml) | Preview the development deployment through OIDC |
| [Dev deployment](.github/workflows/dev-deployment.yml) | Guarded development deployment |
| [Dev cleanup](.github/workflows/dev-cleanup.yml) | Guarded cleanup of scoped development resources |
| [Dev region qualification](.github/workflows/dev-region-qualification.yml) | Validate SQL and App Service regional capacity |

### Portfolio deployment workflows

| Workflow | Purpose |
| --- | --- |
| [Portfolio qualification](.github/workflows/qualification-portfolio.yml) | Select two compatible regions and an App Service SKU, verify identity/quota, estimate cost, validate with Azure providers and run the exact What-If |
| [Portfolio deployment](.github/workflows/deployment-portfolio.yml) | Require the successful qualification run from the exact commit, re-check readiness/cost, run a final What-If and deploy after protected-environment approval |
| [Portfolio cleanup](.github/workflows/cleanup-portfolio.yml) | Remove the short-lived portfolio deployment through a separate guarded operation |

The portfolio deployment does not accept a random qualification result. The workflow checks that the qualification succeeded on the same `main` commit and downloads the exact selected region/SKU profile before deployment.

## Attempt history

### Attempt 1

The first guarded deployment reached Azure and exposed issues that static validation had not detected, including Key Vault behaviour, Azure AI configuration, SQL regional availability, App Service quota, SQL administrator configuration and shared-resource ordering.

The partial environment was inventoried and cleaned up. The Bicep, identity model, dependencies and readiness checks were corrected before another attempt.

[Read the Attempt 1 record](docs/deployment-attempts/deployment-attempt-1-failed.md).

### Attempt 2

The second deployment passed CI, OIDC authentication, readiness checks and the final What-If before Azure resource creation exposed two remaining blockers:

- App Service's separate **Total Regional VMs** quota was zero in the selected regions;
- Azure SQL rejected the Entra administrator payload used at the time.

Cleanup run `32124949474` completed successfully and independent checks found no remaining Nordic Shopping development resources.

The correction added both App Service quota dimensions to the readiness/qualification logic and moved SQL administrator creation to the SQL server resource using an Entra security group with Entra-only authentication.

- [Attempt 2 incident record](docs/deployment-attempts/deployment-attempt-2-controlled-failure.md)
- [Attempt 2 evidence](docs/evidence/attempt-2/README.md)

### Attempt 3 — successful minimal profile

A read-only quota check on 10 September 2026 first identified Sweden Central as
a viable region. On 22 September, the new minimal profile was deployed there
with Bicep and Azure CLI.

The subscription deployment reached `Succeeded` at `13:24:05 UTC`. Three
resource groups and 29 resources tagged for the minimal profile were
inventoried. After the Node.js application was published, `/`, `/health/live`,
`/health/ready` and `/version` returned HTTP 200. The readiness response reported
`keyVault.ok: true`, proving the managed identity, Key Vault RBAC, private DNS
and private endpoint path worked together.

The first successful run was executed locally from the feature branch and was
then integrated through PR #21. A later guarded GitHub Actions run from `main`
completed successfully, published the application, passed readiness on attempt
1 and preserved its workflow artifact and permanent evidence. Settled snapshots
record 95.37% availability over the preceding 24 hours, 36% Azure Policy
compliance and DKK 6.32 actual cost for the main workload resource group.
Cleanup was deferred, so no Attempt 3 zero-resource claim is made.

- [Attempt 3 successful deployment record](docs/deployment-attempts/deployment-attempt-3-successful.md)
- [Attempt 3 evidence](docs/evidence/attempt-3/README.md)
- [GitHub Actions deployment run 35805550250](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/35805550250)
- [Minimal-profile PR #21](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/pull/21)

## Verified results so far

| Check | Result | Evidence |
| --- | --- | --- |
| Bicep formatting, lint and build | Passed | [Infrastructure validation run 32127953187](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32127953187) |
| GitHub Actions OIDC | Passed | Azure sign-in completed in deployment, cleanup and qualification workflows |
| Attempt 2 readiness and final What-If | Passed before resource creation | [Deployment run 32123367196](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32123367196) |
| Attempt 2 regression protection | Passed | [Correction PR #8](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/pull/8) |
| Guarded cleanup | Passed | [Cleanup run 32124949474](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32124949474) |
| Independent zero-resource verification | Passed | Attempt 2 evidence |
| Previous region qualification | Failed to find a compatible pair | [Qualification run 32129650123](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32129650123) |
| 10 Sep quota re-check | West Europe and Sweden Central now show App Service capacity and SQL availability | [Pre-deployment evidence](docs/evidence/attempt-3/pre-deployment-quota-check.md) |
| Attempt 3 Bicep deployment | `Succeeded`; 3 resource groups and 29 tagged resources | [Attempt 3 record](docs/deployment-attempts/deployment-attempt-3-successful.md) |
| Application runtime | `/`, live, ready and version endpoints returned HTTP 200 | [Attempt 3 record](docs/deployment-attempts/deployment-attempt-3-successful.md#runtime-verification) |
| Key Vault readiness | Managed identity and private endpoint access passed | [Attempt 3 record](docs/deployment-attempts/deployment-attempt-3-successful.md#runtime-verification) |
| Minimal profile validation on `main` | Passed | [Run 35748393224](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/35748393224) |
| Attempt 3 GitHub Actions deployment | Passed | [Run 35805550250](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/35805550250) |
| Attempt 3 availability | 95.37% over 24 hours; current 20-minute window 100.00% | [Attempt 3 evidence](docs/evidence/attempt-3/README.md) |
| Attempt 3 Azure Policy snapshot | 36% overall compliance; audit-mode result recorded without claiming full compliance | [Attempt 3 evidence](docs/evidence/attempt-3/README.md) |
| Attempt 3 actual cost | DKK 6.32 for the main workload resource group at capture time | [Attempt 3 evidence](docs/evidence/attempt-3/README.md) |
| Attempt 3 cleanup | Deferred; resources still running | Cleanup and zero-resource evidence remain pending |
| Production deployment | Not attempted | Out of scope |

> A successful Bicep build, What-If or quota check is not the same as a successful deployment. I keep those results separate throughout the repository.

## What this project demonstrates

This project is mainly about the engineering around an Azure migration, not just drawing an architecture diagram.

It demonstrates that I can:

- turn business requirements into Azure architecture and technical controls;
- build reusable subscription-scope infrastructure with Bicep;
- use GitHub Actions and OIDC for Azure delivery without storing a client secret;
- design Entra group-based administration and workload identities;
- use private networking and least-privilege RBAC;
- add governance, cost controls and observability to the platform;
- qualify a live subscription before creating resources;
- separate validation, What-If, deployment and cleanup;
- preserve evidence from failed deployments instead of hiding them;
- use Azure failures to improve regression checks and deployment guardrails;
- clean up short-lived cloud environments and independently verify the result.

## Current project status

### Completed

- business, security, cost and migration documentation;
- target architecture and nine editable Draw.io diagrams;
- modular subscription-scope Bicep;
- development, portfolio and production parameter profiles;
- CI formatting, lint, build and regression validation;
- GitHub Actions OIDC authentication;
- guarded development and portfolio qualification/deployment/cleanup paths;
- two controlled Azure deployment attempts;
- verified cleanup after both attempts;
- root-cause analysis and corrective changes;
- successful single-region minimal-profile deployment;
- live application and Key Vault readiness verification;
- Attempt 3 integration through PR #21 and passing validation on `main`;
- successful guarded GitHub Actions deployment from `main`;
- permanent redacted Attempt 3 evidence items 01–11;
- settled availability, Azure Policy and actual-cost observations.

### Not yet proven

- Attempt 3 guarded cleanup and independent zero-resource verification;
- production deployment;
- live disaster-recovery failover;
- production load/performance validation.

## Documentation

| Document | Contents |
| --- | --- |
| [Business Case](docs/business/01-business-case.md) | Business drivers, expected outcomes and investment case |
| [Business Requirements](docs/business/02-business-requirements.md) | Functional, security, availability and recovery requirements |
| [Current Environment](docs/business/03-current-environment.md) | Existing systems, limitations and risks |
| [Target Architecture](docs/architecture/04-target-architecture.md) | Azure services, topology and resilience |
| [Migration Strategy](docs/migration/05-migration-strategy.md) | Migration waves, testing, cutover and rollback |
| [Cost Estimation](docs/cost/06-cost-estimation.md) | Production planning baseline and cost controls |
| [Security Assessment](docs/security/07-security-assessment.md) | Threats, risks and treatment priorities |
| [Security Strategy](docs/security/08-security-strategy.md) | Identity, network, data and monitoring controls |
| [Project Roadmap](docs/operations/09-project-roadmap.md) | Implementation sequence and gates |
| [Architecture Decisions](docs/architecture/10-architecture-decisions.md) | Main decisions, alternatives and consequences |
| [Attempt 1](docs/deployment-attempts/deployment-attempt-1-failed.md) | First deployment failure and corrections |
| [Attempt 2](docs/deployment-attempts/deployment-attempt-2-controlled-failure.md) | Second controlled failure and cleanup |
| [Attempt 3](docs/deployment-attempts/deployment-attempt-3-successful.md) | Successful minimal deployment, verification and remaining evidence gaps |

## Architecture diagrams

| Diagram | Preview | Editable source |
| --- | --- | --- |
| Architecture overview | [PNG](architecture/diagrams/exports/01-architecture-overview.png) | [Draw.io](architecture/diagrams/source/01-architecture-overview.drawio) |
| Identity and traffic flow | [PNG](architecture/diagrams/exports/02-identity-and-traffic-flow.png) | [Draw.io](architecture/diagrams/source/02-identity-and-traffic-flow.drawio) |
| Regional network and data | [PNG](architecture/diagrams/exports/03-regional-network-and-data.png) | [Draw.io](architecture/diagrams/source/03-regional-network-and-data.drawio) |
| Deployment and operations | [PNG](architecture/diagrams/exports/04-deployment-and-operations.png) | [Draw.io](architecture/diagrams/source/04-deployment-and-operations.drawio) |
| Disaster recovery | [PNG](architecture/diagrams/exports/05-disaster-recovery.png) | [Draw.io](architecture/diagrams/source/05-disaster-recovery.drawio) |
| Full security architecture | [PNG](architecture/diagrams/exports/06-full-security-architecture.png) | [Draw.io](architecture/diagrams/source/06-full-security-architecture.drawio) |
| Current on-premises architecture | [PNG](architecture/diagrams/exports/07-current-on-premises-architecture.png) | [Draw.io](architecture/diagrams/source/07-current-on-premises-architecture.drawio) |
| Migration and cutover flow | [PNG](architecture/diagrams/exports/08-migration-and-cutover-flow.png) | [Draw.io](architecture/diagrams/source/08-migration-and-cutover-flow.drawio) |
| Monitoring and incident response | [PNG](architecture/diagrams/exports/09-monitoring-and-incident-response-flow.png) | [Draw.io](architecture/diagrams/source/09-monitoring-and-incident-response-flow.drawio) |

## How to review this project

If you only have a few minutes:

1. View the [architecture overview](architecture/diagrams/exports/01-architecture-overview.png).
2. Read the [target architecture](docs/architecture/04-target-architecture.md).
3. Review the [Bicep entry point](infra/bicep/main.bicep).
4. Open the [portfolio qualification workflow](.github/workflows/qualification-portfolio.yml) and [portfolio deployment workflow](.github/workflows/deployment-portfolio.yml).
5. Compare the [Attempt 2 evidence](docs/evidence/attempt-2/README.md) with the [successful Attempt 3 record](docs/deployment-attempts/deployment-attempt-3-successful.md).

## Security

Do not commit credentials, connection strings, certificates, access tokens or environment-specific secrets.

See [SECURITY.md](SECURITY.md) for the reporting process and repository security rules.

## Disclaimer

Nordic Shopping is a fictional company created for this portfolio case study. The business scale, requirements, architecture and operating constraints are realistic, but this repository does not represent a production system operated by a real organization.

## License

This project is available under the [MIT License](LICENSE).
