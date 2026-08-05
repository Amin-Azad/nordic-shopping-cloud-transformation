# Nordic Shopping Cloud Transformation — Current Environment

| Item | Approved value |
|---|---|
| Company | Nordic Shopping |
| Document | Current Environment — Final V6 |
| Owner | Amin Azad |
| Version | Final V6 |
| Status | Approved discovery baseline; technical inventory must be validated before build approval |
| Date | 4 August 2026 |
| First issued (discovery baseline) | 2 June 2026 |
| Business source | `docs/business/01-business-case.md` |
| Requirements source | `docs/business/02-business-requirements.md` |
| Target response | `docs/architecture/04-target-architecture.md` |
| Supersedes | All earlier current-environment drafts prior to this Final V6 |

## 1. Purpose

This document describes Nordic Shopping's environment before migration to Azure. It records the business services, on-premises technology, traffic paths, dependencies, operating practices, risks and discovery work that influence the migration.

It is an **as-is baseline**, not a description of the approved Azure design. Azure Front Door, App Service, Azure SQL Database, private endpoints, Bicep, GitHub Actions, centralized Azure monitoring and the Sweden Central recovery environment belong to the target architecture and are not presented here as already deployed.

## 2. Executive summary

Nordic Shopping is a Copenhagen-based e-commerce marketplace with approximately 35 employees, 40,000 registered customers, 150 active vendors and around 600 orders per day. The company currently operates its customer, vendor, administration and API services from a small on-premises environment in one location.

The environment uses Windows-based application hosting, Microsoft SQL Server, shared file storage, a backup server, Active Directory and perimeter network controls. It also connects to external payment, email, SMS and delivery providers.

The platform supports current business operations, but it has material limitations:

- the single physical location is a shared failure domain;
- capacity increases require hardware procurement and manual configuration;
- application and infrastructure changes are largely manual;
- monitoring and audit evidence are fragmented;
- identity, credentials and access controls are not consistently governed;
- backups exist, but there is no tested regional recovery capability;
- maintenance work reduces time available for customer and vendor features; and
- the environment does not provide a proven path to Nordic expansion.

The current platform must remain operational until the migration acceptance gates pass. It will be retained read-only for an approved stabilization and audit period after cutover before decommissioning.

## 3. Business and workload baseline

| Measure | Current baseline |
|---|---:|
| Employees | Approximately 35 |
| Registered customers | Approximately 40,000 |
| Active vendors | Approximately 150 |
| Average daily orders | Approximately 600 |
| Current market | Denmark |
| Current release pattern | Approximately monthly |
| Hosting model | Company-managed on-premises environment |
| Physical locations | One production location |

These values are planning baselines and must be checked against current business and production records during discovery. Peak traffic, seasonal variation, concurrent sessions, request rates, database growth and file-growth rates are not yet evidenced and must be measured before final sizing and load-test approval.

## 4. Current business services

| Service | Users | Current role | Business criticality |
|---|---|---|---|
| Customer website | Customers and visitors | Product discovery, account access and shopping | Critical |
| Customer mobile application | Customers | Mobile commerce client using the platform API | Critical |
| Nordic API | Web, mobile and portal clients | Business logic, transactions and provider integration | Critical |
| Vendor portal | Vendor users | Product, inventory, order and fulfilment activities | High |
| Administration portal | Authorized employees | Operational and administrative management | High |
| SQL database | Applications and administrators | Customers, vendors, catalogue, inventory, orders and references | Critical |
| Shared file storage | Applications and staff processes | Product media, approved documents and application files | High |
| Identity services | Employees and applicable system accounts | Authentication and access administration | High |
| Backup service | IT operations | Local backup and restore capability | High |

The mobile application itself is not hosted as an on-premises server workload. It is a client of the current API and will remain an API client after migration.

## 5. Logical current-state architecture

The current environment is understood at a logical level as follows:

1. Customers, vendors and employees reach the public applications through the internet and the site's perimeter controls.
2. The customer website, Nordic API, vendor portal and administration portal run on Windows-based application hosting.
3. Application components access the on-premises Microsoft SQL Server and shared file storage.
4. The API communicates with external payment, email, SMS and delivery providers.
5. Employee and administrative access depends on Active Directory and locally administered access controls.
6. Backups are written to a company-managed backup server at the same overall site.

The exact server count, virtualization platform, operating-system editions, load-balancing method, firewall model, network ranges, storage capacity and physical topology are not yet approved facts. They must be captured in the discovery inventory rather than assumed in this document.

## 6. Current infrastructure inventory

| Component | Confirmed current position | Information required during discovery |
|---|---|---|
| Application hosting | Windows-based, company managed | Hosts/VMs, versions, CPU, memory, disk, utilization and support status |
| Database | Microsoft SQL Server | Edition/version, instance topology, size, growth, HA configuration, jobs and compatibility |
| File storage | Shared on-premises storage | Capacity, file count, growth, permissions, data classes and backup coverage |
| Backup | Company-managed backup server | Product, schedules, retention, encryption, off-site copy and restore results |
| Directory | Active Directory | Forest/domain design, users, groups, service accounts, federation and legacy authentication |
| Perimeter | Network/firewall controls | Firewall, NAT, certificates, inbound/outbound rules, remote access and DDoS controls |
| Internal network | Single-site connectivity | VLANs/subnets, routing, DNS, segmentation and dependency paths |
| Monitoring | Fragmented local/application monitoring | Tools, coverage, retention, thresholds, routing and incident history |
| Deployment | Primarily manual release process | Build steps, credentials, approvers, rollback, artefact storage and change records |

This table deliberately distinguishes confirmed facts from unknown technical details. Unknown values are discovery actions and must not be converted into invented architecture.

## 7. Current network and traffic flows

| Flow | Current source | Current destination | Main concern |
|---|---|---|---|
| Public application access | Internet users | Site perimeter and application hosting | One-site dependency and limited edge protection evidence |
| Application data access | Application servers | SQL Server | Network and data authorization boundaries require validation |
| Application file access | Application servers | Shared file storage | Permissions, durable-state use and migration scope require validation |
| Employee administration | Employee network/remote access | Admin tools, servers and directory | MFA, privilege separation and remote-access controls require validation |
| Provider API calls | Nordic API | Payment, email, SMS and delivery providers | Secrets, retries, timeouts, reconciliation and egress controls require validation |
| Provider callbacks | External providers | Public application/API endpoint | Signature, replay and duplicate-event controls require validation |
| Backup traffic | Servers and data stores | Backup server | Same-site resilience and restore evidence are insufficient |

All authoritative IP addresses, ports, DNS names, certificates, firewall rules and provider allow-lists must be captured and approved before migration-wave design.

## 8. Identity and access baseline

Active Directory supports the current employee identity environment. Application customer identities, vendor identities, employee access, service accounts and administrator access must be inventoried separately because they have different risk and migration paths.

Known current-state concerns include:

- manually managed credentials and access controls;
- inconsistent least-privilege enforcement;
- incomplete evidence for MFA and conditional access;
- possible shared or long-lived service credentials;
- unclear ownership and review of privileged access; and
- limited centralized audit evidence across applications and infrastructure.

Discovery must record account sources, role mappings, password and MFA policies, dormant accounts, privileged groups, service-account dependencies, certificate ownership, secret locations and joiner/mover/leaver procedures. No identity migration can be approved until customer, vendor, workforce and workload identities are mapped.

## 9. Application and deployment baseline

The current platform contains four logical server applications: Customer Web, Nordic API, Vendor Portal and Admin Portal. The application is treated as a modular monolith for migration planning; Release 1 does not require a microservices rewrite.

Current delivery is largely manual, creating risk from:

- environment-specific configuration;
- non-repeatable infrastructure and application changes;
- credentials used directly during deployment;
- limited automated quality and security gates;
- inconsistent artefact versioning and approval evidence; and
- rollback steps that may depend on individual knowledge.

Discovery must identify source repositories, branches, frameworks, runtime versions, build tools, local disk use, session state, scheduled jobs, background processes, hard-coded endpoints, configuration files, secrets and schema-change procedures. Cloud-readiness work must remove or migrate durable local state and make required workloads compatible with Linux App Service.

## 10. Data environment

### 10.1 Relational data

Microsoft SQL Server is the current transactional data platform. It is expected to contain customer, vendor, product, inventory, order, fulfilment and payment-reference data. The exact schema, size and quality remain discovery items.

The assessment must identify:

- database and table sizes, growth and peak transaction rates;
- SQL Server version, edition and compatibility features;
- stored procedures, triggers, SQL Agent jobs, linked servers and CLR dependencies;
- encryption, access roles, service accounts and administrator permissions;
- backup schedules, retention, restore success and recovery duration;
- duplicate, orphaned or invalid records requiring cleansing; and
- business reconciliation rules for customers, vendors, products, inventory, orders and payment references.

### 10.2 File data

Shared storage contains application files and approved business content. Discovery must classify files, determine ownership and access, calculate counts and checksums, identify local-path dependencies and decide which content is migrated, archived or excluded.

### 10.3 Data protection

Data must be classified as public, internal, confidential or restricted before migration. Full card data and CVV are not intended to be stored by Nordic Shopping; payment-card processing remains with the compliant payment provider. Logs must be checked for tokens, credentials, personal data and payment information before they are migrated or retained.

## 11. External dependencies

| Dependency | Current use | Discovery and migration requirement |
|---|---|---|
| Payment provider | Payment intent, status and callback processing | Confirm API versions, credentials, signing, idempotency, reconciliation and test environment |
| Email provider | Transactional messages | Confirm sender domains, keys, templates, rate limits and failure handling |
| SMS provider | Customer and operational notifications | Confirm credentials, limits, sender configuration, cost and retry behaviour |
| Delivery provider | Fulfilment and delivery events | Confirm API/webhook contract, signing, duplicates, status mapping and reconciliation |
| DNS and certificates | Public service routing and TLS | Confirm registrar, owners, renewal method, expiry dates, TTLs and cutover access |
| Internet connectivity | Public and provider communication | Confirm bandwidth, redundancy, public addressing and outage history |

Provider-owned platforms are not migrated. Their interfaces must be tested from Azure, and production credentials must not be copied into code, pipeline variables or documents.

## 12. Current operations and monitoring

Monitoring is fragmented across infrastructure and applications. There is no confirmed centralized view connecting customer requests, application failures, database health, provider failures, deployments and security events.

The current assessment must capture:

- available logs, metrics and audit records;
- log locations, formats, retention and access controls;
- alert rules, notification routes and responder ownership;
- incident history, detection time, recovery time and unresolved recurring problems;
- daily/weekly operational checks;
- patching, certificate, capacity and backup responsibilities; and
- runbooks, escalation contacts and support hours.

Absence of centralized evidence means that current availability, performance, MTTD and MTTR must not be claimed without validated source data.

## 13. Backup and disaster recovery

Backups exist in the current environment, but the backup server remains within the same overall site dependency. There is no approved evidence of a second-region environment, tested regional traffic failover or an end-to-end exercise meeting the future RTO of 60 minutes and RPO of 15 minutes.

Before migration, the team must validate:

- which servers, databases and files are protected;
- backup frequency, retention, encryption and immutability;
- whether an off-site copy exists;
- the date and result of the most recent restore test;
- achievable current RTO and RPO;
- recovery order and application dependencies;
- who declares an incident and authorizes recovery; and
- how payment, order, inventory and provider states are reconciled after data loss or rollback.

Existing backups must be protected throughout migration. No source system may be decommissioned on the assumption that Azure deployment alone constitutes recovery evidence.

## 14. Current security posture and gaps

| Area | Current limitation or evidence gap | Business risk |
|---|---|---|
| Public ingress | Edge filtering, rate limiting, bot and origin controls are not consistently evidenced | Abuse, application attack and outage |
| Identity | MFA, privileged access, lifecycle and role separation require validation | Account compromise and excessive access |
| Application authorization | Server-side role, ownership and vendor-isolation controls require testing | IDOR/BOLA and cross-vendor data access |
| Network | Segmentation and source/destination rules require full mapping | Lateral movement and unintended exposure |
| Data | Access, encryption, retention and logging controls are inconsistently evidenced | Data disclosure or loss |
| Secrets | Credential storage, rotation and ownership are manually managed | Credential theft and persistent access |
| Software delivery | Manual changes lack consistent automated checks and immutable evidence | Supply-chain compromise and unsafe release |
| Monitoring | Security telemetry and incident correlation are fragmented | Delayed detection and weak investigation evidence |
| Recovery | No tested regional recovery capability | Extended outage, data loss and failed recovery |
| Third parties | Webhook, secret and reconciliation controls require validation | Fraud, duplicates and inconsistent orders |

This is a gap baseline, not a claim that every control is absent. Each item must be confirmed through configuration review, interviews, log evidence and testing.

## 15. Availability, performance and capacity

The single-site design creates common dependencies on local power, internet, perimeter networking, compute, storage and personnel. The current environment has no evidenced regional service continuity.

Before target sizing is accepted, the team must collect at least a representative operating window covering normal and peak periods for:

- requests and transactions per second;
- concurrent users and sessions;
- CPU, memory, disk and network utilization;
- API and page latency percentiles;
- SQL CPU, storage, connections, waits and query performance;
- file count, capacity and growth;
- provider call volume, latency and failure rates; and
- order throughput, failure and retry rates.

The approved Azure starting capacity is therefore a testable target assumption, not a measurement of the current infrastructure.

## 16. Current operational risks

| ID | Risk | Likelihood | Impact | Required treatment |
|---|---|---|---|---|
| CUR-001 | Site, power, network or major hardware failure affects all channels | Medium | Critical | Maintain source protection; implement and test regional target recovery |
| CUR-002 | Local backup cannot support site-loss recovery | Medium | Critical | Validate restore/off-site copy and preserve migration rollback |
| CUR-003 | Hardware capacity cannot respond quickly to demand | Medium | High | Measure peaks and validate Azure load/autoscale design |
| CUR-004 | Manual deployment introduces inconsistency or outage | High | High | Document current process; implement versioned automated delivery |
| CUR-005 | Fragmented monitoring delays incident detection | High | High | Inventory telemetry; define baseline and target alert coverage |
| CUR-006 | Excessive or stale access enables misuse | Medium | High | Perform identity, privilege and service-account review |
| CUR-007 | Unknown application or SQL dependency blocks migration | Medium | High | Complete dependency and compatibility assessment before build gate |
| CUR-008 | Poor source-data quality causes migration errors | Medium | High | Profile, cleanse, reconcile and rehearse twice |
| CUR-009 | Provider callback or retry behaviour creates duplicate/inconsistent orders | Medium | High | Validate signing, idempotency and reconciliation |
| CUR-010 | Limited documentation creates key-person dependency | High | Medium | Capture ownership, procedures, diagrams and runbooks |

Likelihood ratings are preliminary and must be reviewed after technical discovery.

Where a target-state control directly addresses one of these current-state risks, the mapping is recorded in `docs/security/08-security-strategy.md` Section 18.9 (risk traceability), which cross-references CUR-001, CUR-002, CUR-003, CUR-004, CUR-005, CUR-006 and CUR-009 to their corresponding assessment risk and technical control.

## 17. Migration constraints

- The existing platform must continue serving the business during build and rehearsals.
- Migration must not begin until the source inventory and dependency map are approved.
- At least two production-like rehearsals must measure migration, validation and rollback.
- A change freeze and final synchronization window are required for production cutover.
- Customer, vendor, product, inventory, order and payment-reference data require business-approved reconciliation.
- Identity transition must preserve correct customer, vendor and employee access while preventing cross-role and cross-vendor access.
- External providers, DNS and certificates require coordinated test and cutover access.
- The point of no return, rollback criteria and named authority must be agreed before go-live.
- The source environment must remain available for rollback and later read-only retention until decommissioning is approved.
- Hardware, software and licences must not be retired until data, security, operations and audit owners sign off.

## 18. Discovery register required before build approval

| ID | Required evidence | Owner | Exit condition |
|---|---|---|---|
| DIS-001 | Physical/virtual server and application inventory | Infrastructure/Application owners | All production components have owner, version, capacity and support status |
| DIS-002 | Network, DNS, certificate and traffic-flow map | Network owner | All required inbound, outbound and administrative paths are approved |
| DIS-003 | Identity, role, group, privileged and service-account inventory | Identity/Security owners | Every account type has source, owner, role and transition approach |
| DIS-004 | SQL schema, feature, size, performance and data-quality assessment | Data owner | Compatibility and migration blockers are recorded and owned |
| DIS-005 | File inventory, classification, permissions and checksum baseline | Data/Application owners | Migrate, archive and exclude decisions are approved |
| DIS-006 | Application dependency and cloud-readiness assessment | Application owner | Runtime, state, jobs, secrets and compatibility changes are approved |
| DIS-007 | Provider integration and contact register | Product/Application owners | Test endpoints, contracts, credentials and escalation paths are confirmed |
| DIS-008 | Monitoring, incident, backup and restore evidence | Operations owner | Current operational baseline and recovery gaps are accepted |
| DIS-009 | Security configuration and gap validation | Security owner | Findings have severity, treatment, owner and due date |
| DIS-010 | Current cost/licence and hardware lifecycle baseline | Finance/Infrastructure owners | Avoided, retained and one-time costs are documented |
| DIS-011 | Business blackout dates and cutover constraints | Business owner | Approved delivery and migration calendar exists |
| DIS-012 | Data-protection, retention and audit obligations | Security/Business owners | Required classifications and retention decisions are approved |

Build approval requires completion of critical discovery items or formal acceptance of the remaining risk by the named owner.

## 19. Migration scope classification

| Current component | Release 1 disposition |
|---|---|
| Customer Web | Modernize as required and deploy to Azure App Service |
| Nordic API | Modernize as required; retain as the only production business/data-access boundary |
| Vendor Portal | Modernize as required and deploy separately to Azure App Service |
| Admin Portal | Modernize as required and deploy separately to Azure App Service |
| Customer mobile app | Retain as client; update API endpoint/authentication where required |
| Microsoft SQL Server data | Assess, cleanse, rehearse and migrate to Azure SQL Database |
| Shared application files | Classify and migrate approved content to Azure Storage |
| Active Directory-linked access | Map to approved customer, vendor, workforce and workload identity models |
| Payment/email/SMS/delivery platforms | Retain as external providers; update and test integrations |
| Local backup server | Retain through stabilization; decommission only after recovery approval |
| Unrelated corporate systems and end-user devices | Excluded from Release 1 |

## 20. Current-state acceptance criteria

The current-environment baseline is complete enough for build approval only when:

1. every production application, server, database, file store, identity source and external dependency has an owner;
2. infrastructure quantities, versions, utilization and support status are evidenced;
3. authoritative network, DNS, certificate and traffic-flow details are recorded;
4. SQL and application compatibility findings have treatments and owners;
5. source-data and file baselines support repeatable reconciliation;
6. security gaps have severities, owners and agreed treatment;
7. backup and restore capability has been tested and documented;
8. migration blackout, cutover and rollback constraints are approved; and
9. unresolved discovery risks are formally accepted or block the next gate.

## 21. Relationship to the target architecture

The Final V6 target architecture is the approved response to the limitations in this document. It replaces the single-site, manually operated model with managed Azure PaaS, automated delivery, private data access, centralized monitoring and a West Europe active/Sweden Central warm-standby design.

The target is not treated as implemented until Bicep deployments, application migration, security tests, load tests, two migration rehearsals, restore tests, regional failover/failback, operational acceptance and cost validation produce objective evidence.

This document does not change the approved target architecture or any existing architecture diagram.

## 22. Related documents

| Document | Relationship |
|---|---|
| `docs/business/01-business-case.md` | Business drivers, investment and expected outcomes |
| `docs/business/02-business-requirements.md` | Measurable obligations and acceptance gates |
| `docs/architecture/04-target-architecture.md` | Approved Azure implementation response |
| `docs/migration/05-migration-strategy.md` | Migration waves, rehearsals, cutover and rollback |
| `docs/cost/06-cost-estimation.md` | Release 1, migration and future cost estimates |
| `docs/security/07-security-assessment.md` | Security risks and required treatment |
| `docs/security/08-security-strategy.md` | Target security controls and attack defence |
| `docs/operations/09-project-roadmap.md` | Sixteen-week implementation sequence |
| `docs/architecture/10-architecture-decisions.md` | Accepted decisions, alternatives and review triggers |

## 23. Approval statement

Approval of this document confirms that it is the authoritative logical description of Nordic Shopping's current environment for project planning. It does not confirm that every low-level inventory value has already been discovered, that the target environment has been implemented or that migration may proceed without the required gates.

Any discovery result that materially changes workload scope, data classification, application compatibility, recovery risk, security exposure, cost or migration complexity must be recorded through change control and assessed against Business Requirements Final V6, Target Architecture Final V6 and the Architecture Decision Records.
