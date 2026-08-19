# Architecture Decisions

This document records the main choices I made while designing the Nordic Shopping Azure platform. These decisions were used to guide the architecture and Bicep implementation.

They are design choices for a portfolio case study, not decisions approved by a real company.

## ADR-001: Azure Front Door Standard

I chose Azure Front Door Standard as the main public entry point. It provides HTTPS routing, health probes, WAF support and routing between West Europe and Sweden Central.

I did not select Front Door Premium because its additional cost was difficult to justify for the assumed starting workload. Premium should be reconsidered if managed WAF rules, bot protection or private origins become necessary.

## ADR-002: Active region with warm standby

West Europe will be the active region and Sweden Central will be the warm standby.

I chose this instead of active-active because it provides regional recovery with less data and operational complexity. The trade-off is that recovery is not immediate and standby resources still create a monthly cost.

Active-active should be reconsidered if both regions need to serve normal traffic or the recovery time becomes unacceptable.

## ADR-003: App Service instead of AKS or virtual machines

The Customer Web, Nordic API, Vendor Portal and Admin Portal will use Linux Azure App Service.

The workloads are normal web and API applications, so I did not see a clear reason to operate Kubernetes or maintain virtual-machine operating systems.

This decision should be reviewed if the applications later need container orchestration, unsupported runtimes or networking that App Service cannot provide.

## ADR-004: Shared App Service plans

The four applications will have separate App Services but share one P1v3 plan in each region.

West Europe will start with two workers and can scale to four. Sweden Central will keep two standby workers so recovery does not begin by waiting for new compute capacity.

This reduces cost, but one busy application could affect the others. The API or another workload should move to its own plan if monitoring shows repeated contention or a need for independent scaling.

## ADR-005: Azure SQL Database with geo-recovery

I chose Azure SQL Database General Purpose with two provisioned vCores as the starting size.

The primary database will be in West Europe, with zone redundancy planned for the primary and an equal-size geo-secondary in Sweden Central. Promotion of the secondary will remain a controlled decision.

I chose this over SQL Server on virtual machines because Azure SQL removes much of the operating-system, patching and high-availability work.

The tier and size must be reviewed after application and database load testing.

## ADR-006: Private production data services

Production SQL, Blob Storage and Key Vault will use private endpoints and Private DNS. Public network access will be disabled.

This reduces direct exposure of important data services. It also makes DNS, networking and deployment order more important.

Private connectivity does not grant permission by itself. Managed identity, RBAC and SQL database roles are still required.

## ADR-007: API-only data access

The Customer Web, mobile clients, Vendor Portal and Admin Portal will access business data through the Nordic API.

Only the API should receive production access to SQL and Blob data. This creates one place for business rules, auditing and vendor separation.

The API therefore becomes a critical dependency and must be protected, monitored and able to scale.

## ADR-008: Separate identity types

Customers, vendors, employees and Azure workloads have different risks, so they should not share one identity model.

The plan is:

- customer identities through Microsoft Entra External ID;
- vendor access through verified B2B or workforce identities;
- employee access through workforce Entra ID;
- Azure workload access through managed identities.

Application roles and server-side authorization are still required after authentication.

## ADR-009: Managed identity and Key Vault

App Services will use managed identities when accessing supported Azure services.

Credentials for external providers that cannot use managed identity will be stored in Key Vault. The primary and recovery vaults should be managed separately because Key Vault does not automatically replicate secrets between regions.

Provider credentials will still require ownership, rotation and an incident process.

## ADR-010: Bicep for infrastructure as code

I chose Bicep because the project is Azure-only and Bicep provides a clear, Azure-native way to define the resources.

The design uses reusable modules and separate parameter files for development and production.

Terraform may be reconsidered if the project later becomes multi-cloud or needs to follow an organization-wide Terraform standard.

## ADR-011: GitHub Actions with OIDC

GitHub Actions will authenticate to Azure using workload identity federation.

I chose OIDC so that a long-lived Azure client secret does not need to be stored in GitHub. The trust should be restricted by repository, branch and environment.

Separate identities should be used for validation and deployment so each workflow receives only the permissions it needs.

## ADR-012: SQL outbox before Service Bus

For application events, I planned to start with a transactional outbox stored in SQL rather than introduce Service Bus immediately.

This allows the business change and event record to be committed together. It avoids an additional service while the event volume is still unknown.

Service Bus should be reconsidered if event volume, multiple consumers or independent scaling becomes difficult to manage through SQL.

This is an application design decision and is not implemented in the current infrastructure repository.

## ADR-013: Azure Monitor before Microsoft Sentinel

The first monitoring design uses Application Insights, Log Analytics, Azure Monitor alerts and Action Groups.

This provides application and infrastructure visibility without immediately adding the cost and operational work of a full SIEM platform.

Microsoft Sentinel should be reconsidered if the company needs SOC workflows, advanced security correlation, automated response or specific compliance reporting.

## ADR-014: Optional and read-only AI assistance

Any AI Operations Assistant should remain optional, employee-only and read-only.

It may summarize approved monitoring information or runbooks, but it must not deploy resources, change production or activate disaster recovery.

Azure OpenAI should be enabled only after the main monitoring platform is working and there is a clear operational reason to use it. The commerce platform must continue working if the assistant is unavailable.

## ADR-015: Monthly cost boundary

The estimated production baseline is DKK 15,000 per month, with DKK 16,500 used as the upper planning boundary for a normal month.

The higher boundary provides room for usage variation. It is not a target to spend.

The estimate should be rebuilt before a real deployment and reviewed again when compute, SQL, monitoring, traffic or recovery capacity changes.

## ADR-016: Human-controlled disaster recovery

Disaster recovery will not be activated automatically by CI/CD.

A person should first check the incident, replication state and possible data loss. The recovery database can then be promoted, the standby applications checked and Front Door traffic moved.

After recovery, orders, payments and inventory should be checked for missing or duplicate changes.

This manual process adds time, but it reduces the risk of moving production traffic or accepting data loss because of an incorrect automated decision.

## Decisions kept for later

I did not include the following in the first design:

- Front Door Premium;
- active-active regions;
- API Management;
- Service Bus;
- Redis;
- Microsoft Sentinel;
- self-hosted GitHub runners;
- Azure OpenAI in the recovery region;
- AKS;
- customer-facing AI.

These are not automatically bad choices. I left them out because the assumed starting workload did not provide enough evidence to justify their cost and operational complexity.
