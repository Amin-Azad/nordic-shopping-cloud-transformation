# Architecture

This document explains both parts of the Nordic Shopping project:

1. the full two-region Azure architecture;
2. the smaller single-region profile that was deployed and verified.

The project uses managed Azure services because the assumed team is small and should not need to operate virtual machines or a Kubernetes platform for standard web and API workloads.

## Implemented scope

| Area                 | Full design                                               | Deployed minimal profile                                                |
| -------------------- | --------------------------------------------------------- | ----------------------------------------------------------------------- |
| Purpose              | Production-oriented target architecture                   | Affordable deployment and verification profile                          |
| Regions              | West Europe and Sweden Central                            | Sweden Central                                                          |
| Traffic entry        | Azure Front Door Standard with WAF                        | Direct App Service endpoint                                             |
| Applications         | Customer Web, Nordic API, Vendor Portal and Admin Portal  | One Node.js status and readiness application                            |
| Compute              | Separate Linux App Services on shared regional plans      | One Linux App Service on a B1 plan                                      |
| Database             | Primary and geo-secondary Azure SQL databases             | One Azure SQL database                                                  |
| Storage              | Regional Storage accounts                                 | One Storage account                                                     |
| Key management       | Regional Key Vaults                                       | One Key Vault                                                           |
| Networking           | Regional VNets, integration subnets and private endpoints | One VNet with application integration and private endpoints             |
| Private connectivity | SQL, Storage and Key Vault in both regions                | SQL, Blob Storage and Key Vault                                         |
| Identity             | Managed identities and Microsoft Entra groups             | Managed identity verified against Key Vault                             |
| Monitoring           | Regional monitoring, alerts and operational workbooks     | Application Insights, Log Analytics, availability monitoring and alerts |
| Governance           | Policy, budgets, tagging and production controls          | Audit-mode policies, tagging and a subscription budget                  |
| Disaster recovery    | Warm standby and controlled SQL promotion                 | Not included                                                            |
| Deployment status    | Compiled and What-If validated                            | Deployed and verified through GitHub Actions                            |
| Cleanup              | Environment-specific guarded workflows                    | Guarded cleanup and zero-resource verification                          |

The full design represents how I would structure the platform with suitable Azure capacity and a larger operating budget. The minimal profile demonstrates that the Bicep modules, GitHub OIDC authentication, managed identity, private networking, monitoring and application-readiness path work in Azure.

## Deployed minimal profile

The minimal profile was deployed in Sweden Central through a guarded GitHub Actions workflow.

The deployment created three workload resource groups:

* `rg-nshop-dev-sdc`;
* `rg-nshop-dev-network`;
* `rg-nshop-dev-monitor`.

The final GitHub Actions resource inventory contained 45 Azure resources across these groups.

The deployed profile included:

* one Linux App Service plan;
* one Linux App Service;
* one Azure SQL logical server and database;
* one Storage account;
* one Key Vault;
* one virtual network;
* App Service VNet integration;
* private endpoints for SQL, Key Vault and Blob Storage;
* private DNS zones and links;
* managed identities and Azure RBAC assignments;
* Application Insights;
* Log Analytics;
* an availability test;
* action groups and health alerts;
* Azure Policy assignments;
* a subscription budget.

The application package was published to App Service after the infrastructure deployment. The readiness endpoint passed on its first workflow attempt.

The readiness response returned `keyVault.ok: true`. This demonstrated that the following components worked together:

* App Service managed identity;
* Key Vault RBAC;
* VNet integration;
* private DNS resolution;
* the Key Vault private endpoint;
* application configuration.

This runtime check provides stronger evidence than a successful resource deployment alone.

## Full two-region design

The full design uses West Europe as the primary region and Sweden Central as the recovery region.

Public traffic enters through Azure Front Door Standard. Front Door provides TLS termination, health probes, Web Application Firewall integration and routing between the two regional deployments.

The platform contains four application workloads:

* Customer Web;
* Nordic API;
* Vendor Portal;
* Admin Portal.

Each workload has its own Linux App Service so it can be configured and deployed independently. Applications within a region share an App Service plan to control initial cost.

The web applications and portals do not connect directly to SQL or Storage. They use the Nordic API, which acts as the boundary for business logic, authorization and data access.

The starting design is based on approximately:

* 40,000 customers;
* 150 vendors;
* 600 orders per day.

The three-year planning target is:

* 250,000 customers;
* 800 vendors;
* approximately 5,000 orders per day.

The starting capacity has not been presented as proven for the three-year target. App Service, SQL, external-provider limits and application behaviour would need load testing before scaling decisions were made.

![Full architecture overview](../architecture/diagrams/exports/01-architecture-overview.png)

## Regional model

West Europe is the active region in the full design. Its App Service plan starts with two workers and can scale horizontally.

Sweden Central contains a warm standby with the same application structure. It keeps standing compute capacity so recovery does not begin by waiting for new workers to be provisioned.

Azure SQL uses:

* a primary database in West Europe;
* a geo-secondary database in Sweden Central;
* matching database capacity in both regions;
* zone redundancy for the production primary where supported.

Front Door normally routes traffic to West Europe. During a serious regional failure, the recovery database would be promoted, the standby applications checked and traffic moved to Sweden Central.

Database promotion and regional traffic activation remain human decisions. The deployment pipeline must not declare a disaster or accept possible data loss automatically.

The design targets:

* recovery within 60 minutes;
* no more than 15 minutes of potential data loss.

These are design targets, not measured results. Live regional failover and failback were not performed.

## Networking

Each region has its own virtual network and non-overlapping address range.

The regional network contains:

* a delegated subnet for App Service VNet integration;
* a subnet for private endpoints.

SQL Database, Blob Storage and Key Vault use private endpoints and private DNS. Their public network access is disabled in the production configuration.

Separate private DNS zones provide name resolution for the Azure service endpoints. Virtual-network links connect those zones to the regional networks.

Private connectivity does not grant authorization by itself. Managed identity, Azure RBAC and SQL database roles are still required.

The minimal deployment verified the networking pattern in one region. It created private endpoints for SQL, Key Vault and Blob Storage, and the application successfully accessed Key Vault through that private route.

## Identity

GitHub Actions connects to Azure through OpenID Connect federation instead of using a stored Azure client secret.

The trust is restricted to the repository and protected GitHub environment. Deployment and cleanup require explicit confirmation and protected-environment approval.

Azure workloads use managed identities when accessing supported services. Credentials for external services that cannot use managed identity belong in Key Vault.

The full design separates identity types:

* customers through Microsoft Entra External ID;
* vendors through verified B2B or workforce identities;
* employees through workforce Microsoft Entra ID;
* Azure workloads through managed identities;
* deployment automation through GitHub OIDC.

Authentication does not replace application authorization. The Nordic API must still enforce roles, vendor membership, ownership and permitted operations.

## Application and data boundaries

The Nordic API is the only application component intended to access production SQL and Blob data directly.

This creates one boundary for:

* business rules;
* authorization;
* vendor separation;
* input validation;
* auditing;
* transaction handling.

The Customer Web, Vendor Portal and Admin Portal access data through the API.

Azure SQL Database stores transactional data such as customers, vendors, products and orders. Full payment-card information remains with the payment provider.

Storage accounts hold application files. Uploaded files should first enter quarantine and be checked for file type, size and malware before being promoted into trusted storage.

Key Vault stores secrets, certificates and protected configuration that cannot use managed identity directly.

## Monitoring and governance

Application Insights and Log Analytics collect application and infrastructure telemetry.

Azure Monitor alerts cover areas such as:

* application availability;
* HTTP and application errors;
* App Service capacity;
* SQL health;
* resource health;
* service health;
* deployment failures;
* Key Vault access;
* security events;
* unexpected cost increases.

The minimal deployment included an availability test. Its captured 24-hour result was 95.37%, including failures during deployment and application startup. The most recent 20-minute window was 100%.

The deployed policy assignments operated in `Audit` or `AuditIfNotExists` mode. The captured evaluation showed 36% overall compliance. This was recorded as an observed governance result rather than a claim of full compliance.

A production rollout would review the non-compliant resources, correct valid findings and move selected policies to enforcement only after testing their operational effect.

## Deployment model

The infrastructure is written as modular Bicep.

The repository contains two main entry points:

* `infra/bicep/main.bicep` for the full two-region design;
* `infra/bicep/main.minimal.bicep` for the deployed profile.

The remaining environments are:

| Environment | Purpose                                       | Deployment status                                   |
| ----------- | --------------------------------------------- | --------------------------------------------------- |
| `minimal`   | Single-region evidence profile                | Deployed and verified                               |
| `dev`       | Full design with development sizing           | Attempted; blocked by service and quota constraints |
| `prod`      | Full design with stronger production settings | Compiled in CI only                                 |

Development and production use the same core modules with different parameter files and settings.

Production settings include:

* larger App Service capacity;
* multiple workers and autoscale;
* staging slots;
* stronger resilience settings;
* longer log retention;
* resource locks;
* Key Vault purge protection;
* private-only data services;
* additional alerts;
* a higher budget threshold.

GitHub Actions performs:

1. Bicep validation and build.
2. Parameter compilation.
3. Subscription and identity verification.
4. Regional service and SKU checks.
5. Azure What-If.
6. Destructive-change rejection.
7. Protected-environment approval.
8. Deployment after explicit confirmation.
9. Application publication.
10. Readiness verification.
11. Evidence collection.
12. Guarded cleanup and remaining-resource checks.

## Architecture decisions

### Azure Front Door Standard

Azure Front Door Standard is the public entry point for the full design.

It provides HTTPS routing, health probes, WAF integration and regional routing without the additional cost of Front Door Premium.

Premium should be reconsidered if the platform requires managed WAF rules, bot protection or private origins.

### Active region with warm standby

The design uses West Europe as the active region and Sweden Central as a warm standby.

This provides regional recovery with less data and operational complexity than active-active operation. The trade-off is that recovery is not immediate and standby resources still generate cost.

Active-active should be reconsidered if both regions need to serve normal traffic or the recovery time becomes unacceptable.

### App Service instead of AKS or virtual machines

The workloads are standard web and API applications, so Linux App Service was selected instead of Kubernetes or virtual machines.

This avoids operating Kubernetes control-plane components or maintaining guest operating systems without a demonstrated workload requirement.

The decision should be reviewed if the applications later need container orchestration, unsupported runtimes or networking that App Service cannot provide.

### Separate applications on shared plans

The four applications use separate App Services but share one plan per region.

This allows separate deployment and configuration while keeping the starting cost lower.

The trade-off is shared compute capacity. The API or another workload should move to its own plan if monitoring shows contention or a requirement for independent scaling.

### Azure SQL Database

Azure SQL Database General Purpose was selected instead of SQL Server on virtual machines.

The managed service reduces operating-system, patching and high-availability work.

The full design uses a primary and geo-secondary database. The service tier and capacity must be reviewed after application and database load testing.

### Private data services

SQL, Blob Storage and Key Vault use private endpoints and private DNS with public access disabled.

This reduces direct exposure but makes DNS, networking and deployment order more important.

Private connectivity is combined with managed identity, Azure RBAC and database authorization.

### API-only data access

Web clients and portals access business data through the Nordic API.

This centralizes business rules, authorization, auditing and vendor separation. The trade-off is that the API becomes a critical dependency that must be protected, monitored and independently scalable.

### Managed identity and Key Vault

Managed identity is used where Azure services support it.

External-provider credentials remain in Key Vault and require ownership, rotation and incident procedures.

Primary and recovery Key Vaults are managed separately because secrets are not automatically replicated between regions.

### Bicep

Bicep was selected because the project is Azure-only and benefits from an Azure-native infrastructure language.

Reusable modules support the full and minimal entry points.

Terraform could be reconsidered if the platform became multi-cloud or needed to comply with an organisation-wide Terraform standard.

### GitHub Actions with OIDC

GitHub Actions uses workload identity federation rather than a long-lived Azure client secret.

The trust is restricted by repository and environment. A production implementation should further separate validation, deployment and cleanup identities so each receives only the permissions it needs.

### SQL transactional outbox before Service Bus

The application design starts with a transactional outbox in SQL instead of immediately adding Service Bus.

This allows the business change and event record to be committed together while event volume is still unknown.

Service Bus should be reconsidered if multiple consumers, event volume or independent scaling become difficult to manage through SQL.

This pattern is an application decision and was not implemented by the infrastructure deployment.

### Azure Monitor before Microsoft Sentinel

The first monitoring design uses Application Insights, Log Analytics, Azure Monitor alerts and action groups.

This provides operational visibility without immediately adding the cost and operational work of a SIEM platform.

Microsoft Sentinel should be reconsidered if the organisation needs SOC workflows, advanced security correlation, automated response or compliance reporting.

### Optional read-only AI assistance

Any AI operations assistant remains optional, employee-only and read-only.

It may summarize approved monitoring information or runbooks, but it must not deploy resources, change production or activate disaster recovery.

The commerce platform must continue to operate if the assistant is unavailable.

### Human-controlled disaster recovery

Disaster recovery is not activated automatically through CI/CD.

A person first reviews the incident, database replication state and possible data loss. The recovery database can then be promoted, the standby applications checked and Front Door traffic moved.

This adds recovery time but reduces the chance of accepting data loss or moving production traffic because of an incorrect automated decision.

## Services deliberately excluded

The first design does not include:

* AKS;
* virtual machines;
* API Management;
* Service Bus;
* Redis;
* Microsoft Sentinel;
* self-hosted GitHub runners;
* active-active SQL writes;
* customer-facing AI;
* automatic disaster-recovery activation.

These are not rejected permanently. They should be added only when workload, security or operational evidence justifies their cost and complexity.

## Evidence boundary

The repository proves that the minimal single-region profile was deployed through GitHub Actions and that the application reached Key Vault using managed identity and private networking.

The repository also proves that the full design compiles and can be evaluated through Azure What-If.

It does not claim that the full two-region platform, production scale, regional failover or disaster-recovery targets were tested in a live production environment.
