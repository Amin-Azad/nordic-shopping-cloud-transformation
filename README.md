# Nordic Shopping Cloud Transformation

[![Azure](https://img.shields.io/badge/Cloud-Microsoft%20Azure-0078D4?logo=microsoftazure)](https://azure.microsoft.com/)
[![Bicep](https://img.shields.io/badge/IaC-Bicep-0078D4)](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
[![GitHub Actions](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=githubactions)](https://github.com/features/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A production-oriented Azure cloud transformation case study for Nordic Shopping, a fictional e-commerce marketplace migrating from a limited on-premises environment to a secure, scalable, and resilient multi-region cloud platform.

## Project Objectives

- Design a secure Azure landing architecture.
- Migrate customer, vendor, and administration workloads.
- Deploy reusable infrastructure using Bicep.
- Implement CI/CD using GitHub Actions and OIDC.
- Protect public traffic with Azure Front Door and Web Application Firewall.
- Use managed identities, Key Vault, private endpoints, and RBAC.
- Implement centralized monitoring, alerting, and incident response.
- Provide multi-region disaster recovery.
- Validate the architecture through controlled Azure deployments within a 1,300 DKK implementation credit.
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

Detailed architecture diagrams and decisions will be maintained under [`architecture/`](architecture/) and [`docs/architecture/`](docs/architecture/).

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

**Current phase:** Repository and development-environment setup

Architecture and planning documents have been completed. Infrastructure implementation has not started yet.

## Getting Started

Detailed setup and deployment instructions will be added as the Bicep infrastructure and demonstration application are implemented.

## Security

Do not commit credentials, connection strings, certificates, access tokens, or environment-specific secrets.

See [SECURITY.md](SECURITY.md) for the project security policy.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for branch, commit, validation, and pull-request guidelines.

## Disclaimer

Nordic Shopping is a fictional company created for this portfolio case study. The architecture reflects realistic business and technical requirements but does not represent a production system operated by a real organization.

## License

This project is available under the [MIT License](LICENSE).
