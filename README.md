# Nordic Shopping Cloud Transformation

[![Azure](https://img.shields.io/badge/Cloud-Microsoft%20Azure-0078D4?logo=microsoftazure)](https://azure.microsoft.com/)
[![Bicep](https://img.shields.io/badge/IaC-Bicep-0078D4)](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=githubactions)](https://github.com/features/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A production-oriented Azure cloud transformation case study for Nordic Shopping, a fictional e-commerce marketplace migrating from a limited on-premises environment to a secure, scalable, and resilient multi-region cloud platform.

## Implementation Status

The production design is implemented as modular Bicep but has not been deployed
as a production system. Two guarded development attempts were stopped by Azure
subscription and API constraints. Both attempts were cleaned up; no development
resources remain.

| Area | Result | Evidence |
|---|---|---|
| Bicep formatting, lint and build | Passed | [Infrastructure validation 32127953187](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32127953187) |
| GitHub Actions OIDC | Passed | Azure sign-in steps in the deployment, cleanup and qualification runs |
| Provider validation and final What-If | Passed before Attempt 2 resource creation | [Deployment run 32123367196](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32123367196) |
| Complete dev deployment | Not completed | App Service quota and SQL Entra administrator errors |
| Guarded cleanup | Passed | [Cleanup run 32124949474](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32124949474) |
| Attempt 2 regression checks | Passed | [Correction PR #8](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/pull/8) |
| Subscription region qualification | No tested region qualified | [Qualification run 32129650123](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32129650123) |
| Production deployment | Not attempted | Held because of subscription limits and cost governance |

See the [Attempt 2 record](docs/deployment-attempts/deployment-attempt-2-controlled-failure.md)
and [evidence index](docs/evidence/attempt-2/README.md).

## Project Objectives

- Design a secure Azure landing architecture.
- Migrate customer, vendor, and administration workloads.
- Deploy reusable infrastructure using Bicep.
- Implement CI/CD using GitHub Actions and OIDC.
- Protect public traffic with Azure Front Door and Web Application Firewall.
- Use managed identities, Key Vault, private endpoints, and RBAC.
- Implement centralized monitoring, alerting, and incident response.
- Provide multi-region disaster recovery.
- Validate the architecture through controlled Azure deployment attempts with a 1,300 DKK monthly budget guardrail.
- Document technical decisions and migration activities professionally.

## Target Architecture

The proposed platform uses:

- Azure Front Door Standard with Web Application Firewall
- Azure App Service for customer, vendor, administration, and API workloads
- Microsoft Entra ID for workforce identities
- Microsoft Entra External ID for customer and vendor authentication
- Azure SQL Database
- Azure Storage
- Azure Key Vault
- Virtual Network integration and private endpoints
- Azure Monitor, Log Analytics, and Application Insights
- GitHub Actions with workload identity federation
- West Europe as the primary region
- Sweden Central as the disaster recovery region

The approved design uses West Europe as the active primary region and Sweden Central as a warm-standby disaster-recovery region. The normal production planning baseline is approximately DKK 15,000 per month, within a DKK 16,500 authorized operating envelope.

The 1,300 DKK development budget is a Cost Management threshold in the template, not proof of available Azure credit and not a hard spending cap.

## Architecture Overview

[![Nordic Shopping target architecture](architecture/diagrams/exports/01-architecture-overview.png)](architecture/diagrams/exports/01-architecture-overview.png)

The architecture provides separate customer, vendor, administration, and API workloads behind Azure Front Door and WAF. Application services use managed identities and private access to SQL Database, Storage, and Key Vault.

- [View the editable Draw.io source](architecture/diagrams/source/01-architecture-overview.drawio)
- [Read the complete target architecture](docs/architecture/04-target-architecture.md)
- [Review the architecture decisions](docs/architecture/10-architecture-decisions.md)

## Project Documentation

| Document | Purpose |
|---|---|
| [Business Case](docs/business/01-business-case.md) | Business drivers, expected outcomes, investment, and approval request |
| [Business Requirements](docs/business/02-business-requirements.md) | Functional, security, availability, recovery, and acceptance requirements |
| [Current Environment](docs/business/03-current-environment.md) | Existing on-premises systems, limitations, dependencies, and risks |
| [Target Architecture](docs/architecture/04-target-architecture.md) | Approved Azure services, topology, integration, resilience, and operational design |
| [Migration Strategy](docs/migration/05-migration-strategy.md) | Migration waves, testing, cutover, rollback, and stabilization |
| [Cost Estimation](docs/cost/06-cost-estimation.md) | Production baseline, migration costs, growth forecasts, and cost controls |
| [Security Assessment](docs/security/07-security-assessment.md) | Threats, risk ratings, treatment priorities, and residual risk |
| [Security Strategy](docs/security/08-security-strategy.md) | Identity, network, data, application, monitoring, and incident-response controls |
| [Project Roadmap](docs/operations/09-project-roadmap.md) | Sixteen-week implementation sequence, deliverables, and approval gates |
| [Architecture Decisions](docs/architecture/10-architecture-decisions.md) | Approved decisions, alternatives, consequences, and review triggers |
| [Attempt 2 Record](docs/deployment-attempts/deployment-attempt-2-controlled-failure.md) | Guarded deployment outcome, root causes, cleanup and correction |
| [Attempt 2 Evidence](docs/evidence/attempt-2/README.md) | Workflow evidence, screenshot checklist and video notes |

## Architecture Diagrams

| Diagram | Preview | Source |
|---|---|---|
| Architecture overview | [PNG](architecture/diagrams/exports/01-architecture-overview.png) | [Draw.io](architecture/diagrams/source/01-architecture-overview.drawio) |
| Identity and traffic flow | [PNG](architecture/diagrams/exports/02-identity-and-traffic-flow.png) | [Draw.io](architecture/diagrams/source/02-identity-and-traffic-flow.drawio) |
| Regional network and data | [PNG](architecture/diagrams/exports/03-regional-network-and-data.png) | [Draw.io](architecture/diagrams/source/03-regional-network-and-data.drawio) |
| Deployment and operations | [PNG](architecture/diagrams/exports/04-deployment-and-operations.png) | [Draw.io](architecture/diagrams/source/04-deployment-and-operations.drawio) |
| Disaster recovery | [PNG](architecture/diagrams/exports/05-disaster-recovery.png) | [Draw.io](architecture/diagrams/source/05-disaster-recovery.drawio) |
| Full security architecture | [PNG](architecture/diagrams/exports/06-full-security-architecture.png) | [Draw.io](architecture/diagrams/source/06-full-security-architecture.drawio) |
| Current on-premises architecture | [PNG](architecture/diagrams/exports/07-current-on-premises-architecture.png) | [Draw.io](architecture/diagrams/source/07-current-on-premises-architecture.drawio) |
| Migration and cutover flow | [PNG](architecture/diagrams/exports/08-migration-and-cutover-flow.png) | [Draw.io](architecture/diagrams/source/08-migration-and-cutover-flow.drawio) |
| Monitoring and incident-response flow | [PNG](architecture/diagrams/exports/09-monitoring-and-incident-response-flow.png) | [Draw.io](architecture/diagrams/source/09-monitoring-and-incident-response-flow.drawio) |

## Repository Structure

```text
.
├── .github/                  GitHub workflows and issue templates
├── .vscode/                  Shared VS Code configuration
├── app/                      Demonstration application
├── architecture/             Architecture diagrams and exports
├── docs/                     Business and technical documentation
├── infra/bicep/              Azure infrastructure as code
│   ├── environments/         Environment-specific configurations
│   └── modules/              Reusable Bicep modules
├── scripts/                  Validation and deployment utilities
└── tests/                    Infrastructure and application tests
```

## Project Phases

1. Business and current-state assessment
2. Target architecture and security design
3. Repository and development-environment setup
4. Azure infrastructure development with Bicep
5. Application and data migration preparation
6. CI/CD implementation
7. Monitoring and security validation
8. Disaster-recovery testing
9. Documentation and final demonstration

## Project Status

Completed:

- business requirements, current-state assessment and target architecture;
- modular Bicep for development and production configurations;
- GitHub Actions validation and OIDC authentication;
- guarded What-If, deployment and cleanup workflows;
- monitoring, security, cost and disaster-recovery design;
- two controlled dev deployment attempts and verified cleanup; and
- Attempt 2 quota, SQL administrator and regression corrections.

Not completed:

- a full development deployment;
- live application validation; and
- production deployment or disaster-recovery execution.

No further Azure deployment should be attempted until the subscription passes
the repository's qualification checks.

## Review Path

For a short technical review:

1. [Architecture overview](architecture/diagrams/exports/01-architecture-overview.png)
2. [Target architecture](docs/architecture/04-target-architecture.md)
3. [Bicep entry point](infra/bicep/main.bicep)
4. [GitHub Actions workflows](.github/workflows)
5. [Attempt 2 record](docs/deployment-attempts/deployment-attempt-2-controlled-failure.md)
6. [Attempt 2 evidence](docs/evidence/attempt-2/README.md)

## Security

Do not commit credentials, connection strings, certificates, access tokens, or environment-specific secrets.

See [SECURITY.md](SECURITY.md) for the project security policy.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branch, commit, validation, and pull-request guidelines.

## Complete Project Explainer

For a guided walkthrough of the business case, requirements, target architecture, architecture decisions, security model, migration strategy, cost model, diagrams, and implementation sequence, read the [complete project explainer](docs/project-overview/nordic-shopping-cloud-transformation-project-explainer.pdf).

The Markdown documents and Draw.io source files remain the authoritative technical documentation.

## Disclaimer

Nordic Shopping is a fictional company created for this portfolio case study. The architecture reflects realistic business and technical requirements but does not represent a production system operated by a real organization.

## License

This project is available under the [MIT License](LICENSE).
