# Nordic Shopping Cloud Transformation — Migration Strategy

| Document control | Value |
|---|---|
| Version | Final V6 |
| Date | 4 August 2026 |
| First issued | 23 July 2026 |
| Status | Approved planning baseline; implementation evidence pending |
| Owner | Cloud Transformation Project Owner |
| Source environment | Nordic Shopping on-premises environment |
| Target environment | Microsoft Azure — Final V6 architecture |
| Delivery period | 16 weeks |
| Recovery objectives | RPO ≤ 15 minutes; RTO ≤ 60 minutes |
| Normal Azure planning baseline | DKK 15,000/month, excluding VAT |
| Authorized normal-month envelope | DKK 16,500/month, excluding VAT |
| Temporary migration allowance | DKK 14,000–38,000, excluding VAT |

## 1. Purpose

This document defines how Nordic Shopping will move its customer, vendor, administration, API, relational-data and approved file workloads from the current on-premises environment to the approved Azure Release 1 architecture.

It converts the target design into a controlled migration process with discovery, build, testing, two production-like rehearsals, production cutover, rollback, stabilization and source decommissioning. It does not claim that migration is complete before the required evidence is produced and accepted.

This document supersedes all earlier migration-strategy drafts.

## 2. Migration objective

The migration shall modernize the platform without changing the approved architecture or unnecessarily rewriting the business application. The four logical workloads—Customer Web, Nordic API, Vendor Portal and Admin Portal—will be re-platformed to managed Linux App Services. Relational data will move to Azure SQL Database, approved file data to Azure Blob Storage, and secrets to regional Key Vaults.

West Europe will become the active production region. Sweden Central will be deployed and validated as a warm standby. Azure Front Door Standard will provide the only approved public application ingress. Azure OpenAI will remain a West Europe-only, employee-facing, read-only capability and is not required for commerce continuity.

The migration succeeds only when business journeys, data reconciliation, security, operations, recovery, performance and cost acceptance gates pass.

## 3. Strategy decision

Nordic Shopping will use a **phased re-platform migration with controlled cutover**.

| Approach | Decision | Reason |
|---|---|---|
| Direct server-for-server lift-and-shift | Rejected | Retains current operational, scaling and recovery limitations |
| Full application rewrite or microservices conversion | Deferred | Adds avoidable delivery risk and is not required for Release 1 |
| One-step big-bang migration without rehearsal | Rejected | Data, identity, provider and rollback risks are too high |
| Phased re-platform with two rehearsals | Approved | Preserves business capability while proving repeatability and rollback |
| Permanent hybrid operation | Rejected as an end state | Temporary coexistence is permitted only for migration and stabilization |

The application remains a modular monolith in Release 1. Changes are limited to what is required for Linux App Service compatibility, stateless execution, managed identity, Azure SQL, Blob Storage, observability, security and safe deployment.

## 4. Fixed Release 1 destination

The migration must land on the following approved baseline:

- Azure Front Door Standard with TLS, priority routing, custom WAF rules and rate limiting
- App Service origin restrictions and exact Front Door identity validation
- West Europe active and Sweden Central warm standby
- Four separate App Services per region on shared regional P1v3 plans
- Two active App Service workers in West Europe and two standing standby workers in Sweden Central, so DR traffic can be served without a scale-up delay
- Azure SQL Database, zone-redundant primary in West Europe, with a geo-secondary/failover group and controlled promotion
- Private SQL, Blob Storage and Key Vault access in both regions
- Private Azure OpenAI access in West Europe only
- Four private endpoints and corresponding private DNS zones in West Europe; three in Sweden Central
- API-only production access to SQL and Blob data
- Separate regional Key Vaults and managed identities
- Bicep infrastructure and GitHub Actions using OIDC
- Centralized Azure Monitor, Application Insights and Log Analytics telemetry
- Human-authorized cutover, disaster recovery and failback

Front Door Premium, active-active writes, AKS, Terraform, API Management, Service Bus, Redis, Microsoft Sentinel, secondary-region Azure OpenAI and customer-facing generative AI are not part of this migration.

## 5. Scope

### 5.1 In scope

- Current Customer Web, Nordic API, Vendor Portal and Admin Portal
- Required application configuration and Linux/PaaS compatibility changes
- SQL schema, reference data, transactional data and required database objects
- Approved shared-file content that belongs in Blob Storage
- Customer, vendor, workforce and workload identity transition activities
- Payment, delivery, messaging and other confirmed external integrations
- DNS, certificates, domains and provider allow-list changes
- Infrastructure as code, CI/CD, monitoring, alerts and operational runbooks
- Backup, restore, cutover, rollback, regional DR and failback validation
- Temporary parallel operation and approved stabilization retention

### 5.2 Out of scope

- Redesigning Nordic Shopping as microservices
- Replacing payment, delivery or messaging providers without separate approval
- Migrating Microsoft 365 or unrelated corporate endpoints
- Retaining full payment-card data or CVV in Nordic Shopping systems
- Features and services listed as deferred in the architecture decisions
- Decommissioning the source before stabilization and audit acceptance

## 6. Migration principles

1. Protect business continuity and authoritative data before migration speed.
2. Discover and measure before selecting detailed migration tooling.
3. Build the destination through Bicep; do not create an undocumented production environment manually.
4. Use immutable application artifacts and promote the same tested artifact between environments.
5. Keep production data private and access it through managed identities and least privilege.
6. Rehearse the complete procedure at least twice with production-like volume.
7. Reconcile technical records and business totals before accepting data.
8. Keep rollback available until the agreed point of no return.
9. Separate application release rollback from data and traffic rollback.
10. Require named human approval for production cutover, SQL promotion, DR traffic activation and failback.
11. Preserve source backups and evidence until formal decommission approval.
12. Record actual duration, defects, cost and outcomes at every rehearsal and cutover.

## 7. Discovery required before build approval

The current-environment document intentionally leaves unknown facts as discovery items. The team must complete and approve the following inventory before detailed wave execution:

| Area | Required discovery |
|---|---|
| Servers and applications | Hosts, operating systems, runtimes, frameworks, scheduled jobs, local-state use and dependencies |
| SQL Server | Version, edition, size, growth, compatibility, features, collation, jobs, linked servers, encryption and downtime tolerance |
| Files | Locations, size, count, metadata, permissions, owners, growth and retention |
| Identities | Customer/vendor stores, workforce roles, privileged users, service accounts, MFA and account-recovery flows |
| Integrations | Endpoints, certificates, secrets, IP allow-lists, webhooks, retry behaviour, test environments and support contacts |
| Network and DNS | Domains, registrar access, TTLs, certificates, firewall rules, ports and dependencies |
| Operations | Deployment steps, backups, restores, monitoring, incidents, support hours and existing rollback methods |
| Baseline | Traffic, latency, error rates, order volumes, batch windows, SQL load and storage growth |
| Compliance | Data classification, retention, deletion, audit and GDPR responsibilities |

Discovery outputs are an approved inventory, dependency map, data catalogue, compatibility report, migration backlog, risk update and final tool-selection record. Unresolved critical dependencies block the platform-build gate.

## 8. Workload waves

| Wave | Workload | Main treatment | Entry condition | Exit evidence |
|---|---|---|---|---|
| 0 | Foundation | Build Azure, identity, networking, security, monitoring and CI/CD | Discovery approved | Bicep deployment and control tests pass |
| 1 | Non-production applications | Re-platform four workloads to App Service | Foundation ready | Functional, integration and rollback tests pass |
| 2 | Files and database rehearsal copies | Transform and load production-like data | Mapping and scripts approved | Counts, checksums and business totals reconcile |
| 3 | Identities and integrations | Configure role mappings, providers, secrets and callbacks | Test tenants/accounts available | Positive and negative authorization/provider tests pass |
| 4 | Production migration | Final data synchronization and controlled traffic cutover | All go-live gates green | Business and technical validation accepted |
| 5 | Stabilization and retirement | Monitor, reconcile, retain source read-only, then decommission | Cutover accepted | Stabilization and decommission approvals signed |

The waves reduce risk but do not create a partially secured production design. Public production traffic starts only after the complete destination control set is validated.

## 9. Application migration

### 9.1 Required application preparation

Each workload must:

- run on the approved Linux App Service runtime;
- externalize environment-specific configuration;
- remove durable dependence on local disk or in-memory session state;
- use the Nordic API as the production data-access boundary;
- use managed identity for supported Azure access;
- obtain unavoidable provider secrets from the correct regional Key Vault;
- implement health, readiness and dependency checks without exposing secrets;
- produce structured, correlated and privacy-safe telemetry;
- support backward-compatible database changes during the cutover and rollback window; and
- expose no direct production SQL or Blob access from browser clients.

### 9.2 Deployment method

GitHub Actions will build, test, scan and package versioned artifacts. Protected environments, approvals and OIDC will control Azure deployment. Applications deploy to staging slots, warm up, pass smoke tests and then swap. The same approved artifact is promoted; production is not rebuilt from a different source state.

CI/CD may deploy infrastructure and applications. It cannot declare a disaster, accept data loss, promote the DR database or activate Front Door standby traffic.

### 9.3 Release rollback

Slot swap rollback is permitted only while configuration and schema changes remain compatible. Database changes must use an expand-and-contract approach where needed. Destructive schema cleanup occurs after stabilization, not during the initial cutover window.

## 10. Database migration

### 10.1 Tool-selection boundary

The precise database migration tool will be selected after discovery. The decision must consider SQL Server version and features, database size, network throughput, encryption, allowed downtime and whether incremental synchronization is required. A compatibility assessment must confirm that unsupported SQL Server features are removed or redesigned before rehearsal.

Acceptable implementation patterns may include a validated export/import process for a sufficiently small database or a Microsoft-supported online/offline migration method when volume or downtime requires it. The selected method, version and procedure must be recorded and tested; the strategy does not assume a tool without evidence.

### 10.2 Database sequence

1. Inventory schemas, objects, users, jobs, dependencies and unsupported features.
2. Profile and cleanse source data; agree transformation and rejection rules.
3. Create version-controlled schema and data-migration scripts.
4. Deploy the target schema and least-privilege database roles.
5. Load a production-like rehearsal copy through the selected secure path.
6. Validate row counts, checksums, referential integrity and business totals.
7. Measure duration and test incremental/final synchronization where applicable.
8. During cutover, stop or control source writes at the approved checkpoint.
9. Take a final protected backup and record the source checkpoint.
10. Run final synchronization, repeat reconciliation and obtain Data and Business owner acceptance.
11. Enable Azure production writes only after approval.

### 10.3 Reconciliation minimums

Reconciliation must cover:

- table and record counts;
- agreed checksums or hashes;
- orders by status and period;
- payment references and reconciliation states;
- vendor balances, settlements and commissions where applicable;
- customer and vendor account counts;
- inventory or catalogue totals relevant to the platform;
- failed, rejected, duplicated and transformed records; and
- timestamps and the measured potential data-loss window.

Business owners define acceptable zero-tolerance fields and documented thresholds for non-financial discrepancies before the first rehearsal. Unexplained financial, order, payment or authorization differences block cutover.

Azure SQL geo-replication and the failover group are configured and tested for post-migration regional recovery. They do not replace the initial on-premises-to-Azure migration procedure.

## 11. File migration

Only classified and approved files will move to Blob Storage.

1. Inventory file shares, owners, permissions, types, size, count and metadata.
2. Remove or quarantine obsolete, malicious, unsupported or unowned content according to policy.
3. Map file paths and identifiers to target containers and application references.
4. Perform an initial encrypted bulk copy using the discovery-approved Azure method.
5. Validate file count, total bytes, checksums, metadata and application retrieval.
6. Repeat incremental copy during rehearsal and final synchronization during cutover.
7. Upload new untrusted content to a quarantine container, scan it, and promote only approved files to a trusted container.
8. Confirm replication of critical Blob data to the recovery design.

Shared file permissions are not copied blindly into Blob Storage. Access is redesigned through the API, managed identity and application authorization.

## 12. Identity and access transition

Customer, vendor, employee and workload identities have separate migration paths and must not be combined into one shared authorization model.

- Map customer and vendor accounts to the approved external identity design.
- Preserve verified contact identifiers and required consent/audit attributes.
- Define account linking, password transition or reset, duplicate handling and recovery procedures.
- Map vendor users to tenant-scoped roles and test cross-vendor denial.
- Map employees to Workforce identity roles with MFA and Conditional Access.
- assign privileged access separately, using least privilege and approval controls;
- replace application service accounts with managed identities where supported; and
- remove unused accounts and rotate migrated provider credentials.

A pilot cohort must validate registration/sign-in, account recovery, role assignment, session handling and support procedures. Negative tests for IDOR/BOLA, privilege escalation, disabled accounts and cross-vendor access are mandatory before production acceptance.

## 13. External-provider migration

Payment, delivery and messaging integrations require a provider-by-provider plan containing:

- sandbox and production endpoints;
- callback/webhook URLs and Front Door routing;
- credentials stored in Key Vault;
- certificate and signing requirements;
- HMAC/signature, timestamp, nonce and replay controls where supported;
- source-IP or domain allow-list changes;
- idempotency, retry, timeout and circuit-breaker behaviour;
- reconciliation and manual recovery procedure; and
- provider support contact and cutover coverage.

Full payment-card data and CVV must not be introduced into Nordic Shopping systems. Provider-side success and Nordic Shopping order state must be reconciled during rehearsal and cutover.

## 14. Environments and test data

Development, test/staging and production must be logically separated. Production secrets and unrestricted production data may not be copied into lower environments. When representative data is required, it must be minimized, masked or synthetically generated under an approved procedure.

The production-like rehearsal environment must reproduce the migration path, target service configuration, data volume and security controls closely enough to produce meaningful duration, performance and rollback evidence. Any material difference from production must be documented as residual risk.

## 15. Rehearsal plan

At least two complete rehearsals are required.

### Rehearsal 1 — procedure validation

Purpose:

- prove scripts, access, sequencing and initial estimates;
- identify compatibility, data-quality and integration failures;
- test technical rollback; and
- establish the first measured timeline.

The team records every manual step, defect, duration, exception and reconciliation result. The runbook and automation are corrected before Rehearsal 2.

### Rehearsal 2 — production-readiness simulation

Purpose:

- use final production-like volume and the intended cutover team;
- execute the full communications, freeze, backup, synchronization, validation, traffic and rollback sequence;
- prove the outage fits the approved business window;
- demonstrate application, security, monitoring and provider readiness; and
- confirm the point of no return and decision authority.

Rehearsal 2 passes only when there is no unresolved data loss or corruption, all critical journeys work, agreed reconciliation thresholds pass and the timed rollback can be executed within the approved recovery window.

A third rehearsal is required if a material script, schema, identity, provider, volume or topology change occurs after Rehearsal 2, or if its gate does not pass.

## 16. Test and acceptance coverage

| Test area | Minimum evidence |
|---|---|
| Functional | Customer, vendor and admin critical-journey results |
| Integration | Payment, delivery, messaging and webhook results |
| Data | Counts, checksums, integrity and business reconciliation report |
| Identity | Sign-in, recovery, role and negative-authorization results |
| Performance | Baseline comparison, capacity, latency, error rate and scaling results |
| Security | WAF, origin bypass, private access, secret, upload and application-security tests |
| Deployment | Pipeline, staging, smoke, slot swap and rollback history |
| Operations | Dashboards, alerts, incident routing and runbook exercises |
| Backup/restore | Successful restore and validated application use of restored data |
| Regional recovery | Timed failover/failback with RPO ≤15 minutes and RTO ≤60 minutes |
| Cost | Refreshed forecast and temporary migration-consumption report |

Service availability claims or successful resource deployment do not replace end-to-end business testing.

## 17. Production cutover entry criteria

The go/no-go meeting may authorize cutover only when:

- discovery and dependency records are complete;
- the production Azure platform is deployed from approved Bicep;
- production data services have public access disabled;
- Front Door routes work and direct-origin requests are denied;
- all four applications pass functional, integration, security and performance testing;
- two migration rehearsals and the timed rollback pass;
- data mappings and reconciliation thresholds are signed;
- identity and provider transition plans pass;
- backups and restore evidence are current;
- West Europe and Sweden Central readiness is verified;
- the regional recovery exercise meets RPO and RTO;
- monitoring, alerts, support rotas, communications and runbooks are active;
- no unresolved critical or high-risk defect lacks explicit acceptance;
- the current cost forecast remains within DKK 16,500/month or additional funding is approved; and
- the Business sponsor, Project owner, Application owner, Data owner, Security owner and Operations owner approve the change.

## 18. Production cutover runbook

Exact timestamps are finalized after Rehearsal 2. The controlled sequence is:

### Before the change window

1. Confirm go/no-go evidence, named owners, contacts, support coverage and decision authority.
2. Confirm target health, capacity, certificates, DNS access, alerts and provider readiness.
3. Confirm source and target backups, restore points and rollback capacity.
4. Reduce relevant DNS TTLs early enough for the change to take effect.
5. Freeze unrelated releases, schema changes and source housekeeping jobs.
6. Notify employees, vendors, support teams and providers according to the communications plan.

### During the change window

7. Place the source in the approved maintenance/read-only state and stop conflicting jobs.
8. Record the final source transaction/time checkpoint and take the protected final backup.
9. Execute final SQL and Blob synchronization.
10. Run automated and business reconciliation; resolve or formally reject exceptions.
11. Deploy or confirm the approved application artifact and production configuration.
12. Run private-dependency, identity, provider, security and smoke tests.
13. Authorize West Europe production origins in Front Door.
14. Shift traffic gradually while watching health, errors, latency, orders, payments, security and cost signals.
15. Complete customer, vendor and admin business validation.

### After traffic activation

16. Keep the source protected and read-only.
17. Continue transaction and provider reconciliation at agreed intervals.
18. Record incidents, deviations, timings, approvals and the actual point of no return.
19. Close the rollback window only after the Business, Data, Application and Operations owners accept stability.

## 19. Rollback strategy

Rollback is a controlled business decision, not a single technical action.

### 19.1 Rollback triggers

- unexplained financial, order, payment or critical-data mismatch;
- failure of checkout, order processing, vendor fulfilment or administration;
- identity or authorization defect affecting safe access;
- material security-control failure or origin bypass;
- sustained performance or error-rate breach without safe remediation;
- provider integration failure that prevents core trading;
- monitoring or operational failure that makes production unsafe; or
- cutover exceeding the approved window before the point of no return.

### 19.2 Point of no return

Before cutover, the Business and Data owners approve the exact point after which returning to the on-premises platform would risk losing or duplicating accepted Azure transactions. Until that point, Azure writes must be prevented or captured in a tested reversible mechanism.

If significant production writes have occurred in Azure, rollback requires an approved reverse-reconciliation or transaction-replay procedure. DNS reversal alone is not a valid rollback because it may create split-brain data and duplicate payments or orders.

### 19.3 Rollback sequence

1. Incident commander pauses the cutover and gathers technical and business evidence.
2. Authorized owners decide whether the approved rollback criteria are met.
3. Stop or isolate Azure writes and record the final Azure checkpoint.
4. Reconcile any Azure-only transactions using the rehearsed procedure.
5. Restore or re-enable the source at the approved consistent point.
6. Return public traffic to the source and validate critical journeys.
7. Notify stakeholders and providers.
8. Preserve logs, backups and evidence; open an incident review.

Application-only failures may use staging-slot rollback when the database and configuration remain compatible. Data rollback follows the separate procedure above.

## 20. Disaster recovery after migration

Production cutover and regional disaster recovery are different procedures. After migration, a declared West Europe incident follows the approved DR runbook:

1. Detect and classify the regional incident.
2. Validate that recovery is safer than remaining in West Europe.
3. Measure replication state and expected data loss.
4. Obtain Business and Data owner acceptance of any data loss.
5. Obtain authorized disaster declaration and recovery approval.
6. Promote the Sweden Central SQL secondary through the controlled process.
7. Verify the Sweden Central applications, secrets, private services and providers are healthy at standing two-worker capacity.
8. Activate the approved Front Door standby origins.
9. Run business smoke tests and reconciliation.

CI/CD cannot declare the disaster, approve data loss, promote recovery or activate DR traffic. The employee AI assistant may remain unavailable because Azure OpenAI is West Europe only and is not a critical commerce dependency. Failback is a separately approved change after replication, reconciliation and security validation.

## 21. Stabilization and source decommissioning

### 21.1 Stabilization

Weeks 15–16 are the initial stabilization period. The team will:

- monitor critical journeys, errors, latency, security, capacity and provider health;
- reconcile orders, payments, vendor activity and files daily at first;
- resolve migration defects under the agreed severity process;
- validate the first Azure cost data against the DKK 15,000 baseline;
- tune alerts, autoscale and WAF custom rules through controlled changes; and
- maintain the source as protected read-only unless rollback is authorized.

Stabilization may be extended when business cycles, audit needs or unresolved risks require more evidence.

### 21.2 Decommission gate

The on-premises production environment may be decommissioned only after:

- the rollback and retention periods have expired with formal approval;
- data and provider reconciliation is complete;
- Azure backup, restore and regional recovery evidence is accepted;
- legal, audit and retention obligations are confirmed;
- required records and configuration are archived securely;
- credentials, certificates, DNS records and provider allow-lists are rotated or removed;
- assets and licences are recorded for disposal or reuse; and
- the Business, Data, Security and Operations owners sign the decommission record.

Data-bearing equipment must be sanitized through the approved disposal process. Backups are not deleted merely because application servers are retired.

## 22. Schedule alignment

| Roadmap phase | Weeks | Migration outcome |
|---|---:|---|
| Mobilization | 1 | Owners, inventory, risks, budget and communication established |
| Engineering foundation | 2–3 | Repository, Bicep, OIDC, environments and governance ready |
| Core Azure platform | 4–5 | Approved target platform deployed and secured |
| Application and CI/CD | 6–8 | Four workloads deploy and roll back safely |
| Security and observability | 9–10 | Controls, telemetry, detection and operations validated |
| Migration rehearsals | 11–12 | Two repeatable migrations, reconciliation and rollback proven |
| DR and operational readiness | 13 | Restore, failover, failback, RPO and RTO proven |
| Production cutover | 14 | Controlled migration and Front Door activation completed |
| Stabilization | 15–16 | Business acceptance, cost validation and handover completed |

If a phase gate fails, the dependent phase does not begin merely to preserve the calendar.

## 23. Roles and decision authority

| Role | Migration responsibility |
|---|---|
| Business sponsor | Funding, business risk, final go/no-go and material data-loss acceptance |
| Project owner | Plan, dependencies, gate coordination, communications and evidence register |
| Application owner | Compatibility, application testing, deployment and application rollback |
| Data owner | Classification, mapping, reconciliation, RPO and data acceptance |
| Platform/DevOps owner | Azure build, networking, pipelines, Front Door and deployment evidence |
| Security owner | Security gates, risk acceptance, logging and incident readiness |
| Operations owner | Monitoring, support, cutover command, DR operation and handover |
| QA/Product representatives | Critical journeys, UAT and defect acceptance |
| Finance/FinOps owner | Forecast, budget alerts, migration allowance and invoice review |
| Provider owners | Payment, delivery and messaging coordination and reconciliation |

No individual may silently approve their own unresolved high-risk exception. Production cutover, rollback after the point of no return, disaster declaration, SQL promotion, DR traffic activation and failback require the named authority in the approved runbook.

## 24. Communications plan

| Audience | Minimum communication |
|---|---|
| Employees and support | Schedule, expected impact, escalation route, status and completion |
| Vendors | Portal impact, order-handling guidance, support contact and completion |
| Customers | Maintenance notice only when user impact is expected; clear status updates |
| Payment/delivery/messaging providers | Test/cutover schedule, callback changes, validation contact and rollback status |
| Executive/change authority | Gate evidence, go/no-go, major incident, rollback and final outcome |
| Technical team | Command channel, responsibility roster, decision log and timed checkpoints |

Only an authorized communications owner publishes customer-facing status. Messages must not expose security-sensitive implementation details.

## 25. Cost control during migration

The recurring target estimate is DKK 13,950/month plus DKK 1,050 contingency, producing the DKK 15,000 planning baseline. Normal-month Azure consumption is authorized up to DKK 16,500. Migration, testing, rehearsals, parallel operation and DR exercises use the separate DKK 14,000–38,000 temporary allowance.

Controls include:

- tagged migration and environment resources;
- budget alerts with named recipients;
- weekly temporary-consumption review during build and rehearsals;
- shutdown or removal of unused non-production resources;
- pre-cutover Azure Pricing Calculator refresh;
- explicit approval for a normal-month forecast above DKK 16,500; and
- post-cutover invoice validation and forecast correction.

Temporary migration capacity must not become permanent production capacity without an updated cost estimate and approval.

## 26. Migration risk register

| ID | Risk | Treatment | Owner |
|---|---|---|---|
| MIG-R01 | Incomplete dependency inventory causes outage | Discovery gate, dependency map and owner sign-off | Project/Application owner |
| MIG-R02 | SQL feature incompatibility delays migration | Early assessment, prototype and remediation backlog | Data owner |
| MIG-R03 | Poor source-data quality breaks reconciliation | Profiling, cleansing rules and two rehearsals | Data/Business owner |
| MIG-R04 | Cutover exceeds the approved window | Timed rehearsals, incremental sync and go/no-go checkpoints | Project owner |
| MIG-R05 | Azure and source both accept writes | Maintenance/read-only controls and tested point of no return | Application/Data owner |
| MIG-R06 | Rollback loses or duplicates transactions | Checkpoints, idempotency, reconciliation and replay procedure | Data/Provider owner |
| MIG-R07 | Identity transition locks out users or crosses vendor boundaries | Pilot cohorts, recovery plan and negative authorization tests | Identity/Application owner |
| MIG-R08 | Provider callbacks fail after DNS/routing change | Sandbox tests, allow-list updates and provider coverage | Provider owner |
| MIG-R09 | Direct origin or public data access remains open | Automated access and private-endpoint tests | Security/Platform owner |
| MIG-R10 | DR is assumed rather than proven | Timed restore, failover and failback exercise | Operations/Data owner |
| MIG-R11 | Temporary cost exceeds allowance | Tags, alerts, weekly review and expiry dates | FinOps owner |
| MIG-R12 | Source is retired too early | Read-only retention and signed decommission gate | Operations owner |
| MIG-R13 | Team fatigue causes cutover error | Roster, handovers, time limits and rollback threshold | Project owner |
| MIG-R14 | Migration exposes personal or secret data | Encryption, masking, least privilege and log review | Security/Data owner |

## 27. Evidence register

The following artefacts must be version-controlled or stored in the approved evidence location:

- approved discovery inventory and dependency map;
- compatibility and data-quality reports;
- migration tool decision and versioned scripts;
- infrastructure deployment and Bicep what-if results;
- pipeline, artifact and approval history;
- application, integration, identity, performance and security results;
- Rehearsal 1 and Rehearsal 2 reports;
- reconciliation reports and business sign-offs;
- backup, restore, DR and failback evidence;
- cutover timeline, command log, go/no-go and rollback decisions;
- cost forecast, alerts and temporary-consumption report;
- stabilization reports, incident records and lessons learned; and
- source-retention and decommission approval.

Evidence must show who performed the action, when it occurred, which version was tested, the result, exceptions and the approving owner.

## 28. Success criteria

The migration is accepted when:

- critical customer, vendor and administration journeys operate correctly through Front Door;
- the source and Azure data reconcile within pre-approved thresholds with no unexplained critical discrepancy;
- public data-service access and direct App Service origin access are denied as designed;
- releases, application rollback and the migration rollback procedure are proven;
- regional recovery and failback meet RPO ≤15 minutes and RTO ≤60 minutes;
- monitoring, alerts, incident response and operational ownership are active;
- normal production cost is forecast within DKK 16,500/month or revised funding is approved;
- the source remains recoverable throughout the approved rollback period; and
- all mandatory owners sign production and stabilization acceptance.

## 29. Related authoritative documents

| Subject | Document |
|---|---|
| Investment and outcomes | `docs/business/01-business-case.md` |
| Measurable requirements | `docs/business/02-business-requirements.md` |
| As-is baseline | `docs/business/03-current-environment.md` |
| Approved destination | `docs/architecture/04-target-architecture.md` |
| Cost baseline and future estimates | `docs/cost/06-cost-estimation.md` |
| Security assessment | `docs/security/07-security-assessment.md` |
| Security implementation | `docs/security/08-security-strategy.md` |
| Delivery schedule | `docs/operations/09-project-roadmap.md` |
| Architecture decisions | `docs/architecture/10-architecture-decisions.md` |

## 30. Final approval statement

This V6 strategy is the authoritative migration plan for the approved Final V6 architecture. It does not introduce Front Door Premium, active-active operation or any other deferred capability. It requires a phased, measured and reversible move from the current on-premises platform to West Europe, followed by validation of the Sweden Central warm standby.

Approval of this document authorizes detailed migration preparation and rehearsal. It does not by itself authorize production cutover, data-loss acceptance, disaster declaration, DR activation, failback or source decommissioning. Those actions remain subject to their evidence gates and named human approvals.
