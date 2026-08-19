# Nordic Shopping Cloud Transformation — Architecture Decisions

| Document | Architecture Decision Record Collection |
|---|---|
| Version | Final V6 (ADR collection) |
| Date | 4 August 2026 |
| First issued | 3 August 2026 |
| Decision scope | Release 1 production baseline and defined evolution paths |
| Architecture status | Approved for implementation, subject to delivery gates |
| Normal-month planning baseline | DKK 15,000 excluding VAT |
| Approved monthly budget | DKK 16,500 excluding VAT |

## 1. Purpose

This document records the important architecture choices for the Nordic Shopping cloud transformation. It explains what will actually be implemented, why each choice was made, which alternatives were considered, what trade-offs are accepted and when a decision must be reviewed.

The approved target architecture and the Release 1 implementation baseline are the same design. Future options are recorded as possible evolution paths; they are not shown as already deployed.

## 2. Decision authority and usage

- These records govern the Bicep implementation, CI/CD pipelines, security controls, migration, operations and cost approvals.
- A decision marked **Accepted** is part of the Release 1 baseline.
- A decision marked **Deferred** is excluded until its review trigger is reached and a new ADR is approved.
- Delivery teams must not silently substitute a lower-cost or less-secure design.
- Any change affecting cost, security, recovery objectives, data residency or public traffic requires architecture review.
- Implementation evidence—not this document alone—determines production readiness.

## 3. Architecture baseline

| Area | Approved Release 1 decision | Strategic evolution |
|---|---|---|
| Edge | Azure Front Door Standard with custom WAF rules | Premium when managed protection or private origins are required |
| Regional model | West Europe active; Sweden Central warm standby | Reassess active-active only when justified by business demand |
| Hosting | Linux Azure App Service Premium v3 | Split plans or reassess platform if isolation/scale requires it |
| Data | Azure SQL Database with failover group | Scale tier or redesign from measured workload evidence |
| Integration reliability | SQL transactional outbox | Service Bus when independent event processing is justified |
| Identity | External ID, B2B/workforce identity and managed identities | Expand governance as user and partner complexity grows |
| Infrastructure | Bicep | Reassess Terraform only for a genuine multi-cloud requirement |
| Delivery | GitHub Actions with OIDC | Private runners only if deployment-access policy requires them |
| Monitoring | Azure Monitor, Application Insights and Log Analytics | Add Microsoft Sentinel when SOC/SIEM needs justify it |
| AI | Employee-only, read-only Operations Assistant in West Europe | Add DR AI only if it becomes operationally critical |
| Budget | DKK 15,000 planning baseline; DKK 16,500 authorization | Reforecast at capacity, security and growth triggers |

## 4. Decision summary

| ADR | Decision | Status | Primary reason |
|---|---|---|---|
| ADR-001 | Azure Front Door Standard | Accepted | Cost-controlled global Layer 7 ingress and failover |
| ADR-002 | Active/warm-standby regional model | Accepted | Meets recovery goal without active-active cost and complexity |
| ADR-003 | Azure App Service instead of AKS or VMs | Accepted | Managed PaaS matches team size and workload |
| ADR-004 | Shared regional App Service plans; SWC raised to 2 standing workers (V6) | Accepted | Efficient initial capacity with application separation and delay-free DR failover |
| ADR-005 | Azure SQL Database and failover group, zone-redundant primary (V6) | Accepted | Managed relational platform, controlled regional recovery and zone-level resilience |
| ADR-006 | Private PaaS data plane | Accepted | Prevent direct public access to production data services |
| ADR-007 | API-only production data access | Accepted | Central authorization and vendor isolation boundary |
| ADR-008 | Separate identity models | Accepted | Correct separation of customers, vendors, employees and workloads |
| ADR-009 | Managed identities and Key Vault | Accepted | Minimize secrets and constrain provider credentials |
| ADR-010 | Bicep as infrastructure as code | Accepted | Azure-native, repeatable implementation aligned with current skills |
| ADR-011 | GitHub Actions with OIDC | Accepted | Short-lived deployment authentication without stored Azure secrets |
| ADR-012 | SQL transactional outbox before Service Bus | Accepted | Reliable local transactions without premature messaging complexity |
| ADR-013 | Azure-native monitoring before Sentinel | Accepted | Required observability at an appropriate initial operating cost |
| ADR-014 | West Europe-only Operations Assistant | Accepted | AI is advisory and non-critical during DR |
| ADR-015 | DKK 16,500 approved monthly budget | Accepted | Reconciles funding with the final architecture |
| ADR-016 | Controlled, human-authorized disaster recovery | Accepted | Prevent unsafe or premature traffic activation |

## 5. ADR-001 — Azure Front Door Standard

**Status:** Accepted for Release 1
**Decision owner:** Architecture and Security owners

### Context

Nordic Shopping needs one global HTTPS entry point, custom domains, health probes, caching, application routing and controlled regional failover. The platform also needs edge request filtering while keeping launch cost proportionate to the current business scale.

### Decision

Deploy Azure Front Door Standard with one route and origin group per public application. Associate a WAF policy using tuned custom match and rate-limit rules. Lock App Service origins to Azure Front Door backend traffic and require the correct `X-Azure-FDID` value.

Front Door Standard is both the **approved target architecture** and the **Release 1 implementation**. Premium was considered but was never approved as the current target.

### Alternatives considered

| Alternative | Outcome | Reason |
|---|---|---|
| Front Door Premium | Deferred | Higher base cost; current design can launch with custom rules and origin restrictions |
| Application Gateway | Rejected | Regional rather than the required global entry and failover service |
| Azure Load Balancer | Rejected | Layer 4 service; unnecessary for managed public App Services |
| Direct App Service exposure | Rejected | Creates inconsistent public entry points and allows edge-control bypass |

### Consequences and compensating controls

- Standard does not provide the Premium managed WAF rule sets, managed bot protection or Private Link origins used by this design's future option.
- Custom WAF and rate-limit rules require tuning and operational ownership.
- Origins remain public endpoints at platform level but are protected by App Service access restrictions, Front Door service-tag filtering, exact Front Door ID validation, default deny and monitoring.
- Parameterized SQL, input validation, secure headers, tenant authorization and application throttling remain mandatory; WAF is not the only defence.

### Review and upgrade triggers

Upgrade to Front Door Premium when managed OWASP or bot rules are required, custom-rule maintenance becomes excessive, attack volume or sophistication exceeds the compensating controls, compliance requires managed protection, or private origin connectivity becomes mandatory.

## 6. ADR-002 — West Europe active and Sweden Central warm standby

**Status:** Accepted
**Decision owner:** Architecture, Operations and Business owners

### Decision

Run normal production traffic in West Europe. Maintain Sweden Central as a warm standby with deployed applications, regional network and private services, an equal-size SQL geo-secondary and replicated critical Blob data. Both regions run a standing minimum of two App Service workers, so no compute scale-up is required before serving DR traffic (see the V6 addendum to ADR-004 for the full rationale).

### Alternatives considered

- **Single region:** rejected because it cannot meet the approved regional recovery objective.
- **Active-active application and data writes:** deferred because it adds conflict handling, data consistency, testing and operating cost not justified by Release 1 demand.
- **Cold standby:** rejected because provisioning during an incident makes the RTO too uncertain.

### Consequences

- Recovery is not instantaneous. SQL promotion, dependency validation, compute scale-out and traffic activation must complete before serving write traffic.
- Standby capacity incurs continuous cost even when it serves no business traffic.
- Asynchronous replication can lose recent writes; reconciliation remains mandatory.

### Review trigger

Review active-active when regional traffic becomes continuous and business-critical, the tested RTO cannot satisfy the business, or Nordic expansion requires both regions to serve normal traffic.

## 7. ADR-003 — Azure App Service instead of AKS or virtual machines

**Status:** Accepted
**Decision owner:** Architecture and Application owners

### Decision

Host Customer Web, Nordic API, Vendor Portal and Admin Portal as separate Linux Azure App Services on Premium v3 plans. Use deployment slots, health checks, autoscale and managed identities.

### Rationale

The workload is a conventional web/API platform. App Service supplies managed runtime hosting, patching, TLS integration, scaling, deployment slots and regional availability without requiring the team to operate Kubernetes or guest operating systems.

### Alternatives considered

- **AKS:** rejected for Release 1 because its orchestration and security-operating burden is disproportionate to the workload.
- **Virtual machines:** rejected because patching, clustering, load balancing and OS operations add avoidable work.
- **Azure Functions:** rejected as the main platform because the core workload is a continuously available web/API system rather than primarily event-driven functions.

### Review trigger

Reassess only if workloads require container orchestration, unsupported runtimes, specialized networking, sustained worker processes or portability requirements that App Service cannot meet.

## 8. ADR-004 — Shared App Service plans within each region

**Status:** Accepted with monitoring
**Decision owner:** Platform and FinOps owners

### Decision

Use one P1v3 Linux App Service plan per region for the four applications. West Europe starts with two workers and autoscale up to four; Sweden Central runs a standing minimum of two workers at all times.

**V6 addendum (accepted):** the original V5 decision kept Sweden Central at one warm worker and scaled to two only after a disaster was declared. Review showed this made the standby region's very first response to a real regional incident an untested scale-up event, at the moment resilience matters most. Sweden Central is raised to a standing minimum of two workers, matching West Europe's floor and removing the scale-up step from the DR critical path. Cost impact: +DKK 1,450/month, reflected in `docs/cost/06-cost-estimation.md`.

**V6 addendum, part 2 (zone redundancy, accepted):** running two workers in a region is instance resilience, not zone resilience, unless the plan is explicitly marked zone-redundant. Because both regions now meet the minimum-instance floor for zone redundancy on Premium v3 (two instances), both the West Europe and Sweden Central App Service plans are configured `zoneRedundant: true`. This is a configuration change with no additional per-instance cost — the instances already being paid for are simply distributed across availability zones instead of left to land in one. It closes the gap between "two workers are running" and "two workers survive a zone failure," and matches the zone-redundancy decision made for the SQL primary in ADR-005.

### Consequences

- Applications are logically separate but share regional CPU and memory capacity.
- One noisy workload can affect the others, so per-application telemetry, limits, health checks and capacity alerts are required.
- Deployment slots do not create separate compute capacity.
- Sweden Central now carries standing compute cost even outside a declared incident; this is treated as the price of a tested, delay-free failover rather than idle spend.

### Review trigger

Move the API or another workload to a dedicated plan when it repeatedly consumes more than 60% of shared capacity, causes resource contention, requires independent scaling/isolation or has materially different availability needs.

## 9. ADR-005 — Azure SQL Database with failover group

**Status:** Accepted
**Decision owner:** Data and Architecture owners

### Decision

Use Azure SQL Database General Purpose with provisioned compute, a **zone-redundant primary** in West Europe, a like-for-like geo-secondary in Sweden Central and a failover group listener. Use Microsoft Entra authentication, map the API managed identity to least-privilege database roles and promote the secondary only through the authorized DR process.

**V6 addendum (accepted):** the original V5 decision left the West Europe primary without zone redundancy, so the design's 99.9% availability target rested on a single-zone database even though the DR story covered whole-region loss. The primary database is now deployed zone-redundant within West Europe, removing the single largest disclosed gap between the stated availability target and what the architecture actually protected against. Cost impact: +DKK 200/month, reflected in `docs/cost/06-cost-estimation.md`.

### Alternatives considered

- **SQL Server on VMs:** rejected because it adds operating-system, patching, backup and HA management.
- **Cosmos DB:** rejected because the transactional relational domain and migration source fit SQL.
- **Active-active writes:** rejected because conflict resolution and consistency complexity are not justified.
- **Automatic uncontrolled failover:** rejected initially because business dependencies and possible data loss must be assessed before write traffic moves.

### Consequences

- Target SQL RPO is no more than 15 minutes and end-to-end RTO no more than 60 minutes, proven by tests rather than assumed from the service.
- A forced failover may lose recent transactions.
- Payment, order, inventory and webhook reconciliation is required after unplanned failover.

### Review trigger

Resize or change tier after query tuning when measured CPU, data IO, log IO, latency, storage or concurrency exceeds the agreed threshold. Redesign only if the relational model or recovery requirement materially changes.

## 10. ADR-006 — Private production data services

**Status:** Accepted
**Decision owner:** Platform and Security owners

### Decision

Disable public network access to Azure SQL, Blob Storage and Key Vault in both regions and to Azure OpenAI in West Europe. Connect through service-specific private endpoints and Private DNS zones.

West Europe has four private endpoints and four corresponding zones: SQL, Blob, Key Vault and Azure OpenAI. Sweden Central has three: SQL, Blob and Key Vault. Azure OpenAI has no DR endpoint in Release 1.

### Consequences

- DNS, VNet integration and deployment sequencing become critical dependencies.
- Private connectivity does not grant authorization; Entra identity, RBAC and SQL database permissions are still required.
- Tests must prove private resolution and access before public access is disabled.

### Review trigger

Reassess network topology if centralized egress, inspection, hub-and-spoke connectivity or additional private services become necessary.

## 11. ADR-007 — The API is the only production data-access boundary

**Status:** Accepted
**Decision owner:** Application and Security owners

### Decision

Customer Web, mobile clients, Vendor Portal and Admin Portal call the Nordic API. Only regional API managed identities receive authorized production access to SQL and Blob data. Presentation applications do not connect directly to production data services.

Every request is authenticated and receives server-side role, permission, object and vendor-tenant authorization. Client-supplied tenant identifiers are never trusted by themselves.

### Consequences

- Authorization, auditing, throttling and business rules have one enforcement boundary.
- The API is a critical dependency and must scale, fail safely and expose useful health signals.
- IDOR/BOLA and cross-vendor negative tests are mandatory release gates.

## 12. ADR-008 — Separate customer, vendor, employee and workload identities

**Status:** Accepted
**Decision owner:** Identity and Security owners

### Decision

- Use Microsoft Entra External ID external tenant for customer identities.
- Use verified B2B/workforce identity for vendor and employee access, with application roles and tenant-scoped authorization.
- Require MFA and Conditional Access for privileged workforce access and use PIM for eligible administration.
- Use managed identities for Azure workloads rather than shared service accounts.

### Alternatives considered

- **One shared identity model for every actor:** rejected because lifecycle, risk, assurance and authorization requirements differ.
- **Locally stored application passwords:** rejected because it creates avoidable credential and recovery risk.
- **Long-lived workload secrets:** rejected where managed identity or federation is available.

### Review trigger

Review tenant structure and identity governance when vendor onboarding volume, partner federation, regulatory obligations or customer-identity requirements materially change.

## 13. ADR-009 — Managed identities and regional Key Vaults

**Status:** Accepted
**Decision owner:** Platform and Security owners

### Decision

Assign a system-managed identity to each App Service. Use identity-based access for Azure SQL, Blob Storage, Key Vault and Azure OpenAI where supported. Store unavoidable payment, delivery and messaging provider credentials in a regional Key Vault with RBAC, private access, purge protection, soft delete, diagnostics and expiry alerts.

Maintain regional secrets independently; do not describe Key Vault as automatically replicated across regions.

### Consequences

- Role assignments and SQL contained users become deployment dependencies.
- Provider secrets still require rotation and incident procedures.
- Vault access must be least privilege and auditable.

## 14. ADR-010 — Bicep as the infrastructure-as-code language

**Status:** Accepted
**Decision owner:** Platform owner

### Decision

Implement reusable Bicep modules and environment parameter files for shared, West Europe and Sweden Central resources. Current CI runs formatting, linting, builds and regression validation, and the dev workflow supports `what-if`. Dedicated security scanning remains planned before production delivery.

### Alternatives considered

- **Terraform:** deferred. It offers multi-cloud portability but adds another state and toolchain where the present scope is Azure-only.
- **Portal-only deployment:** rejected because it is not repeatable, reviewable or suitable for DR parity.
- **ARM JSON authored directly:** rejected because Bicep provides a clearer Azure-native authoring model.

### Review trigger

Reassess Terraform only if Nordic Shopping adopts a material multi-cloud strategy, a shared organizational standard requires it, or the team accepts the migration and state-management cost.

## 15. ADR-011 — GitHub Actions with OIDC workload federation

**Status:** Accepted
**Decision owner:** DevOps and Security owners

### Decision

Use GitHub Actions with Microsoft Entra workload identity federation. Restrict federated credentials by organization, repository and protected environment/branch context. Use separate, least-privilege identities for infrastructure and application deployment, protected production approvals and immutable application-artifact promotion.

### Alternatives considered

- **Client secret stored in GitHub:** rejected because it creates a long-lived deployment credential.
- **Personal Azure credentials:** rejected because deployment must not depend on an individual.
- **Self-hosted VNet runner:** deferred until private SCM or source-IP-restricted deployment is mandatory.

### Consequences

- OIDC trust configuration and GitHub environment protection are security-critical.
- Workflows need only the permissions required to request the OIDC token and perform the approved deployment.
- CI/CD may deploy infrastructure and applications but cannot authorize or activate DR traffic.

## 16. ADR-012 — SQL transactional outbox before Service Bus

**Status:** Accepted for Release 1
**Decision owner:** Application and Architecture owners

### Decision

Commit business state and an outbox record in one SQL transaction. Process pending events asynchronously with idempotency, retry, dead-letter state and monitoring. Do not introduce Service Bus in Release 1.

### Rationale and trade-off

This avoids a dual-write gap and supplies reliable processing without adding a message broker before workload evidence justifies it. It couples outbox throughput to SQL and offers less independent scaling than a brokered design.

### Review trigger

Introduce Service Bus when event volume, fan-out, independent scaling, cross-service decoupling, delivery semantics or operational isolation exceed the SQL outbox design.

## 17. ADR-013 — Azure-native observability before Microsoft Sentinel

**Status:** Accepted; Sentinel deferred
**Decision owner:** Operations and Security owners

### Decision

Use workspace-based Application Insights, Log Analytics, Azure Monitor alerts, Action Groups, Azure Activity Log and service diagnostics for Release 1. Route Front Door/WAF, App Service, Entra, SQL audit, Storage, Key Vault, deployment and cost signals into the approved monitoring design.

### Consequences

- Operations must own dashboards, alert tuning, retention, runbooks and evidence.
- This is not presented as a full SOC or enterprise SIEM capability.
- Retention is configured by data classification and investigation requirements.

### Review trigger

Adopt Microsoft Sentinel when formal SOC workflows, cross-source correlation, advanced threat analytics, security automation or regulatory SIEM requirements justify licensing, ingestion and staffing cost.

## 18. ADR-014 — Employee-only Operations Assistant in West Europe

**Status:** Accepted
**Decision owner:** Operations, Security and Data Protection owners

### Decision

Deploy one private Azure OpenAI resource in West Europe for a read-only employee Operations Assistant. It may summarize approved telemetry and runbook excerpts but cannot execute commands, change resources, activate DR or make business decisions. Use managed identity, redaction, bounded inputs, usage limits, audit and a feature kill switch.

### Alternatives considered

- **Customer-facing generative AI:** out of scope because it adds product-safety and privacy requirements unrelated to the initial operational use case.
- **A second AI deployment in Sweden Central:** deferred because AI is non-critical during DR.
- **Autonomous remediation:** rejected because operational changes require deterministic automation and human authorization.

### Review trigger

Add regional AI resilience only if the assistant becomes operationally mandatory during DR. Any write or autonomous capability requires a separate security, safety and architecture decision.

## 19. ADR-015 — Revised cost baseline and budget authorization

**Status:** Accepted as the planning decision; sponsor approval required at mobilization
**Decision owner:** Sponsor and FinOps owner

### Context

The original DKK 10,000 ceiling and DKK 6,700–7,200 estimate were created before the final quantities, P1v3 capacity, SQL geo-secondary, private endpoints, WAF, monitoring, security and warm-standby requirements were fully reconciled.

### Decision

Use DKK 15,000 per month as the normal-operation planning baseline and seek authorization for DKK 16,500 per month, excluding VAT, labour and third-party transaction charges. The additional authorization is operating headroom, not a spending target.

### Consequences

- The business case and target-architecture header must be updated; they must not continue to present DKK 10,000 as sufficient for the complete design.
- A cost-optimized DKK 9,000–10,500 launch is a separate reduced-cost option and cannot silently replace the approved target.
- Monthly budgets, forecasts, variance review and service-level cost allocation are mandatory.
- Seasonal and growth costs require new approval according to the final cost model.

### Review trigger

Reforecast before deployment, before cutover and monthly after launch; also review when sustained load changes compute, SQL, telemetry, security tier, egress or DR capacity.

## 20. ADR-016 — Human-authorized disaster recovery

**Status:** Accepted
**Decision owner:** Incident commander and DR owner

### Decision

Use a controlled sequence for regional recovery:

1. Declare and classify the regional incident.
2. Freeze conflicting changes and assess replication state.
3. Record the possible data-loss decision.
4. Obtain incident-commander authorization.
5. Promote the SQL secondary when required.
6. Validate Sweden Central identity, network, secrets, data and provider dependencies.
7. Scale standby compute and run security/business smoke tests.
8. Activate the approved Front Door standby origins.
9. Reconcile data and monitor service restoration.

CI/CD cannot declare an incident, approve data loss or activate DR traffic. Failback is a separate planned change, never an automatic reversal.

### Consequences

- Manual control reduces unsafe failover risk but adds time to recovery.
- Twice-yearly exercises must prove RPO no more than 15 minutes and RTO no more than 60 minutes.
- If the targets repeatedly fail, the business must fund automation/capacity changes or formally revise the objectives.

## 21. Deliberately deferred capabilities

| Capability | Release 1 position | Trigger for a new decision |
|---|---|---|
| Front Door Premium | Deferred | Managed WAF/bot protection, private origins, compliance or attack pressure |
| Active-active regions | Deferred | Sustained regional demand or stricter availability requirement |
| API Management | Deferred | Productized APIs, subscriptions, developer portal, advanced policies or partner scale |
| Service Bus | Deferred | Outbox cannot meet event scale, decoupling or delivery needs |
| Redis cache | Deferred | Proven latency or database-load bottleneck after application/SQL tuning |
| Microsoft Sentinel | Deferred | SOC/SIEM correlation, automation or compliance requirement |
| Self-hosted/private runner | Deferred | Private SCM or deployment-source policy requirement |
| Azure OpenAI in DR | Deferred | AI becomes critical to recovery-region operations |
| AKS | Rejected for current scope | Workload requirements exceed App Service capabilities |
| Terraform | Deferred | Material multi-cloud or organizational standard |
| Customer-facing AI | Out of scope | Approved product case plus privacy, safety and cost assessment |

## 22. Cross-document consistency actions — resolved

Earlier review cycles identified the corrections below as required before the documentation set could be declared final. All are confirmed resolved in the current Final V6 document set and are retained here only as an audit trail:

| Document | Correction required (historical) | Status |
|---|---|---|
| `docs/business/01-business-case.md` | Replace the DKK 6,700–7,200 estimate and DKK 10,000 ceiling with the final cost decision | Resolved — document states DKK 15,000 baseline / DKK 16,500 envelope throughout |
| `docs/architecture/04-target-architecture.md` | Change the monthly ceiling and cost gates to the DKK 16,500 authorization and DKK 15,000 baseline | Resolved |
| `docs/architecture/04-target-architecture.md` | Correct the private-DNS inventory: four service zones in WEU and three in SWC; the OpenAI zone is WEU-only | Resolved — see Section 8.3 |
| Security control documentation | Apply the reviewed regional endpoint, SQL authorization, upload quarantine, provider-secret, retention and DR-authorization clarifications | Resolved — see `docs/security/08-security-strategy.md` |
| All implementation documents | Describe Front Door Premium, Sentinel, active-active, Service Bus and Terraform only as deferred alternatives or triggered evolution | Resolved — see Section 21 above and each document's deferred-capabilities section |

This ADR collection and `docs/cost/06-cost-estimation.md` remain the governing sources for these decisions going forward.

## 23. Decision governance

### 23.1 When a new ADR is required

A new or superseding ADR is required when a proposal:

- changes an Accepted service, region, trust boundary or data-access path;
- changes RPO, RTO, availability or security posture;
- enables a deferred capability;
- increases the approved normal-month budget;
- introduces a new public endpoint, identity store or sensitive-data processor;
- gives AI or automation permission to change production; or
- creates a material new operational skill requirement.

### 23.2 ADR lifecycle

```text
Proposed → Reviewed → Accepted → Implemented → Validated
                         ↓
                  Superseded or Rejected
```

Each new record must identify its owner, context, decision, alternatives, consequences, security and cost impact, implementation evidence and review trigger.

## 24. Implementation validation

These decisions are considered implemented only when the project produces the following evidence:

- Bicep deployment and `what-if` results with no unexplained drift;
- Front Door routing, WAF and direct-origin denial tests;
- identity, RBAC, SQL role and cross-vendor authorization tests;
- private DNS resolution and public-access denial tests;
- OIDC trust-boundary and protected-environment evidence;
- immutable artifact promotion and deployment rollback evidence;
- monitoring, alert and incident-runbook tests;
- secure regional failover and failback results meeting RPO/RTO;
- restored SQL and Blob data from isolated recovery tests; and
- invoice/forecast evidence within the approved DKK 16,500 normal-month budget.

## 25. Final decision statement

The Release 1 architecture is a deliberate, cost-aware target—not a temporary diagram hiding a different implementation. Azure Front Door Standard, managed Azure PaaS, warm standby, private data services, API-only data access, separate identities, Bicep, OIDC and controlled DR are the approved choices.

Premium services and more complex operating models remain visible as evolution paths with measurable triggers. They will be adopted only when business value, risk or scale justifies their additional cost and operational responsibility.
