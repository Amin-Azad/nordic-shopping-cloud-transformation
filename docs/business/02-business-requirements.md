# Nordic Shopping Cloud Transformation — Business Requirements

| Item | Approved value |
|---|---|
| Company | Nordic Shopping |
| Document | Business and Non-Functional Requirements |
| Owner | Amin Azad |
| Version | Final V6 |
| Status | Approved requirements baseline; subject to controlled change |
| Date | 4 August 2026 |
| First issued | 9 June 2026 |
| Business source | `docs/business/01-business-case.md` |
| Architecture response | `docs/architecture/04-target-architecture.md` |
| Financial source | `docs/cost/06-cost-estimation.md` |

## 1. Purpose

This document defines what the Nordic Shopping Cloud Transformation must achieve and how acceptance will be demonstrated. It governs architecture, implementation, migration, security, operations and production readiness.

Requirements use unique identifiers and mandatory language:

- **Shall** means required for Release 1 acceptance.
- **Target** means a measurable objective that must be validated before it becomes an operating commitment.
- **Deferred** means excluded from Release 1 unless approved through change control.

Choosing an Azure service does not by itself satisfy a requirement. Evidence from configuration, testing, monitoring or approval is required.

## 2. Business baseline

| Measure | Current baseline | Three-year planning target |
|---|---:|---:|
| Employees | 35 | 80 |
| Registered customers | 40,000 | 250,000 |
| Active vendors | 150 | 800 |
| Daily orders | 600 | 5,000 |
| Markets | Denmark | Denmark, Sweden and Norway |
| Release frequency | Monthly | Weekly or on demand |

Release 1 shall support the current workload and the agreed peak-load profile. The three-year target shall be addressed through measured scaling and capacity reviews; it is not an acceptance claim for the initial resource sizing.

## 3. Business requirements

| ID | Requirement | Priority | Acceptance evidence |
|---|---|---|---|
| BR-001 | The platform shall continue supporting customer shopping, checkout, account and order-tracking journeys during the migration. | Must | UAT and cutover checklist |
| BR-002 | Vendors shall manage only their own products, inventory, fulfilment and order data. | Must | Cross-vendor authorization tests |
| BR-003 | Authorized employees shall perform support, finance, reporting and operational tasks through controlled roles. | Must | Role matrix and access tests |
| BR-004 | The transformation shall reduce dependency on the current single physical site through a tested regional recovery capability. | Must | Timed DR exercise |
| BR-005 | The platform shall support weekly or on-demand releases without material customer interruption. | Must | Slot deployment and rollback test |
| BR-006 | The platform shall support growth without requiring immediate replacement of the Release 1 architecture. | Must | Load results and scaling thresholds |
| BR-007 | Cloud consumption shall be transparent, attributable and governed within the approved financial envelope. | Must | Cost dashboard, tags and budget alerts |
| BR-008 | The delivery shall provide runbooks, ownership and training so the internal team can operate the platform. | Must | Operational acceptance record |
| BR-009 | The AI Operations Assistant shall remain advisory, employee-only and non-critical to commerce operations. | Must | Access/control and failure-isolation tests |

## 4. Functional requirements

### 4.1 Channels and application boundary

| ID | Requirement | Acceptance evidence |
|---|---|---|
| FR-001 | Customer Web and the existing customer mobile application shall consume commerce capabilities through the Nordic API. | Integration tests |
| FR-002 | Vendor Portal and the existing vendor mobile application shall consume vendor capabilities through the Nordic API. | Integration tests |
| FR-003 | Admin Portal shall consume administrative capabilities through the Nordic API. | Integration tests |
| FR-004 | Customer, vendor and mobile presentation channels shall not connect directly to production SQL, Blob Storage or Key Vault. | Permission review and negative tests |
| FR-005 | The Nordic API shall be the sole production boundary for business logic, data access, auditing and server-side authorization. | Architecture/configuration review |

### 4.2 Commerce capabilities

| ID | Requirement | Acceptance evidence |
|---|---|---|
| FR-006 | The solution shall support customer registration, authentication and account access. | UAT and identity tests |
| FR-007 | The solution shall support catalogue browsing, product search and product detail retrieval. | Functional and performance tests |
| FR-008 | The solution shall support cart, checkout, order creation and order-status workflows. | End-to-end UAT |
| FR-009 | Payment-provider operations shall use secure requests, idempotency and reconciliation to prevent untracked duplicate or missing outcomes. | Provider integration tests |
| FR-010 | Vendor users shall manage approved catalogue, price, stock and fulfilment functions only within their vendor boundary. | Role and tenant-isolation tests |
| FR-011 | Employees shall access only the support, finance, reporting or operational actions assigned to their roles. | Access-control test report |
| FR-012 | External payment and delivery webhooks shall validate signature, timestamp and replay status before processing. | Forgery and replay tests |
| FR-013 | File uploads shall enter quarantine, pass approved malware scanning and be promoted to trusted storage only after a clean result. | Malicious-file and promotion tests |

## 5. Availability, reliability and recovery requirements

| ID | Requirement | Target/control | Acceptance evidence |
|---|---|---|---|
| NFR-AVL-001 | Customer-facing services shall target monthly end-to-end availability of at least 99.9%. | ≥99.9% after service acceptance | Synthetic and monthly service report |
| NFR-AVL-002 | Production in West Europe shall run at least two active App Service workers. | Minimum 2 | Configuration and failure test |
| NFR-AVL-003 | The application shall expose health endpoints that represent application and critical-dependency readiness. | Continuous probes | Probe and failure-injection tests |
| NFR-AVL-004 | Planned releases shall avoid material customer interruption. | Slot-based release | Warm-up, smoke, swap and rollback evidence |
| NFR-REL-001 | Retriable business operations shall be idempotent and support reconciliation. | Orders, payments, inventory and webhooks | Duplicate/retry tests |
| NFR-DR-001 | West Europe shall be active and Sweden Central shall remain a deployed warm standby. | Active-passive | Regional configuration review |
| NFR-DR-002 | The end-to-end Recovery Time Objective shall be 60 minutes or less. | RTO ≤60 minutes | Timed regional exercise |
| NFR-DR-003 | The Recovery Point Objective for covered business data shall be 15 minutes or less. | RPO ≤15 minutes | Replication and reconciliation evidence |
| NFR-DR-004 | Recovery shall include SQL promotion, dependency validation, standby scale-out, origin activation, smoke testing and reconciliation. | Controlled sequence | Approved DR exercise record |
| NFR-DR-005 | CI/CD shall not declare a disaster, accept data loss or activate DR traffic. | Human authority only | Permission test and runbook review |
| NFR-DR-006 | Backup restore, regional failover and failback shall be tested before production acceptance and at the approved recurring frequency. | Test programme | Test reports and defect closure |

Availability, RTO and RPO are end-to-end business targets. They are not assumed from individual Azure service-level agreements.

## 6. Performance and scalability requirements

Final test traffic profiles, payload sizes and concurrency shall be agreed during discovery. Unless discovery replaces them with approved baselines, the following initial targets apply under the agreed Release 1 load:

| ID | Requirement | Initial target | Acceptance evidence |
|---|---|---:|---|
| NFR-PER-001 | Customer pages shall become usable within the agreed browser test profile. | p95 ≤3 seconds | Browser performance test |
| NFR-PER-002 | Product search API requests shall complete within the target. | p95 ≤2 seconds | Load-test report |
| NFR-PER-003 | Checkout API processing, excluding external-provider latency, shall complete within the target. | p95 ≤1 second | Load-test report |
| NFR-PER-004 | General API requests shall meet the latency target, excluding approved long-running operations. | p95 ≤500 ms | Application Insights/load test |
| NFR-PER-005 | The system shall process the current 600 daily-order baseline and the agreed peak multiplier without breached error or latency thresholds. | Profile approved in discovery | Capacity test |
| NFR-SCL-001 | West Europe application compute shall scale horizontally from two to four workers using approved metrics and cooldowns. | 2–4 workers | Autoscale test |
| NFR-SCL-002 | Sweden Central shall normally retain a minimum of two standing workers so DR traffic can be served without a scale-up delay. | 2 standing; ≥2 serving | DR exercise |
| NFR-SCL-003 | Per-application telemetry shall identify shared-plan contention and trigger separation review. | Review at sustained >60% shared capacity or material contention | Capacity report and ADR review |
| NFR-SCL-004 | Capacity shall be reviewed before new-country launch and when order, concurrency, SQL, storage or telemetry thresholds are crossed. | Trigger-based | Approved capacity review |

## 7. Identity and authorization requirements

| ID | Requirement | Acceptance evidence |
|---|---|---|
| SEC-IAM-001 | Customers shall authenticate through Microsoft Entra External ID. | Sign-in and token-validation tests |
| SEC-IAM-002 | Vendors shall use verified B2B/workforce identities and vendor-scoped application authorization. | Onboarding and isolation tests |
| SEC-IAM-003 | Employees shall use workforce Entra ID with MFA and Conditional Access appropriate to risk. | Policy and sign-in evidence |
| SEC-IAM-004 | Privileged roles shall be least-privilege, time-bound where supported and reviewed regularly. | PIM/RBAC configuration and access review |
| SEC-IAM-005 | Every App Service shall use a system-assigned managed identity for supported Azure access. | Resource and role-assignment review |
| SEC-IAM-006 | The API shall validate token issuer, audience, signature and lifetime, then enforce role, action, ownership and vendor boundary server-side. | Positive and negative authorization tests |
| SEC-IAM-007 | Client-supplied user, role or vendor identifiers shall not be trusted without server-side authorization context. | IDOR/BOLA test report |
| SEC-IAM-008 | Emergency and privileged access shall be logged, reviewed and separable from routine administration. | Audit and access-review evidence |

## 8. Application, network and data-security requirements

| ID | Requirement | Acceptance evidence |
|---|---|---|
| SEC-APP-001 | Azure Front Door Standard shall be the only approved public ingress for application traffic. | DNS, routing and direct-origin tests |
| SEC-APP-002 | Front Door shall enforce HTTPS, custom WAF controls and rate limits appropriate to Release 1 risks. | WAF policy and attack tests |
| SEC-APP-003 | App Service origins shall default-deny non-Front-Door traffic using approved origin restrictions and Front Door identity validation. | Origin-bypass test |
| SEC-APP-004 | Applications shall use parameterized data access, input validation, output encoding, secure headers and safe error handling. | SAST/DAST and code-test evidence |
| SEC-APP-005 | APIs shall enforce request-size, rate and abuse controls appropriate to each route. | Abuse and load tests |
| SEC-NET-001 | Each region shall contain an application-integration subnet and a dedicated private-endpoint subnet. | Bicep and deployment review |
| SEC-NET-002 | SQL, Blob Storage and Key Vault shall have public network access disabled in both regions. | Configuration and negative tests |
| SEC-NET-003 | Azure OpenAI shall be private and available only in West Europe in Release 1. | Endpoint and DNS test |
| SEC-NET-004 | West Europe shall use private endpoints/DNS for SQL, Blob, Key Vault and Azure OpenAI; Sweden Central shall use SQL, Blob and Key Vault only. | Regional DNS-resolution tests |
| SEC-NET-005 | Private connectivity shall never replace identity and authorization controls. | Permission-negative tests |
| SEC-DAT-001 | Data shall be encrypted in transit and at rest using supported platform controls. | Configuration and TLS tests |
| SEC-DAT-002 | The API managed identity shall map to least-privilege Azure SQL database roles; Azure RBAC alone shall not be treated as SQL data access. | Database role review |
| SEC-DAT-003 | Provider credentials that cannot use federation or managed identity shall be stored in the regional Key Vault and rotated. | Vault inventory and rotation test |
| SEC-DAT-004 | Key Vault soft delete, purge protection, diagnostics and expiry monitoring shall be enabled. | Configuration evidence |
| SEC-DAT-005 | Logs shall not expose secrets, authentication tokens, payment data or unnecessary personal data. | Log review and security tests |
| SEC-DAT-006 | Retention shall be configured by data classification, legal need and investigation requirement. | Approved retention schedule |

## 9. Privacy and compliance requirements

| ID | Requirement | Acceptance evidence |
|---|---|---|
| CMP-001 | Personal data processing shall follow GDPR principles including purpose limitation, minimization and controlled retention. | Data-flow and privacy review |
| CMP-002 | Access to personal and commercial data shall be auditable and limited to approved business roles and workloads. | Audit and access review |
| CMP-003 | Data deletion, correction and subject-request procedures shall remain supported after migration. | Procedure and functional test |
| CMP-004 | Production data use in non-production shall require masking or approved synthetic data. | Non-production data review |
| CMP-005 | Payment card data shall not be stored unless separately approved; payment providers shall retain regulated payment processing responsibility. | Integration and data inventory review |
| CMP-006 | Security incidents involving personal data shall follow the approved incident and breach-assessment procedure. | Tabletop exercise |

## 10. Monitoring and operational requirements

| ID | Requirement | Acceptance evidence |
|---|---|---|
| OPS-001 | Application, dependency, infrastructure and deployment telemetry shall be centralized in Application Insights and Log Analytics. | Searchable telemetry and correlation test |
| OPS-002 | Front Door, Entra, App Service, SQL, Storage, Key Vault, Azure Activity and pipeline events required for investigation shall be captured. | Log-source coverage matrix |
| OPS-003 | Alerts shall cover availability, HTTP 5xx, latency, compute capacity, SQL health, replication, security control failures, deployment failures and budget thresholds. | Alert catalogue and fired tests |
| OPS-004 | Critical alerts shall reach named primary and secondary responders and record acknowledgement. | Routing exercise |
| OPS-005 | Dashboards shall show service health, business-critical dependencies, recovery state and cost. | Operational review |
| OPS-006 | Every production service and alert shall have an owner, severity, response instruction and escalation path. | Ownership/runbook register |
| OPS-007 | Operational metrics shall include availability, MTTD, MTTR, failed-release rate, recovery results and cost variance. | Monthly service report template |

## 11. Delivery, infrastructure and change requirements

| ID | Requirement | Acceptance evidence |
|---|---|---|
| DEV-001 | Azure infrastructure shall be defined in modular, version-controlled Bicep. | Repository and deployment evidence |
| DEV-002 | The same regional modules shall create equivalent primary and standby controls with documented exceptions. | Template comparison and deployment test |
| DEV-003 | GitHub Actions shall authenticate to Azure through OIDC workload federation without stored Azure client secrets. | Trust and secret review |
| DEV-004 | CI/CD shall run linting, tests, security scans, Bicep validation/what-if and environment approvals before production changes. | Pipeline execution record |
| DEV-005 | Applications shall deploy immutable artifacts to staging slots in both regions; production swap shall require smoke tests and human approval. | Release evidence |
| DEV-006 | Database changes shall be backward-compatible for the release and rollback window. | Migration/rollback test |
| DEV-007 | Production changes shall be traceable to source revision, pipeline run, artifact and approver. | Audit sample |
| DEV-008 | Architecture changes affecting cost, security, recovery, data residency or public traffic shall require an ADR and impact assessment. | Change-control record |

## 12. Migration requirements

| ID | Requirement | Acceptance evidence |
|---|---|---|
| MIG-001 | Current applications, dependencies, data, integrations, identities and operating procedures shall be inventoried before build approval. | Discovery register |
| MIG-002 | Applications shall be made stateless where required and local durable state shall be removed or migrated. | Cloud-readiness test |
| MIG-003 | Migration scripts and procedures shall be version-controlled, repeatable and restricted to approved operators. | Repository and permission review |
| MIG-004 | At least two production-like migration rehearsals shall validate duration, counts, checksums, business totals, final synchronization and rollback. | Rehearsal reports |
| MIG-005 | The business shall approve data validation rules for customers, vendors, products, inventory, orders and payment references. | Signed reconciliation plan |
| MIG-006 | Cutover shall use approved entry criteria, change freeze, communication plan, final sync, validation and go/no-go authority. | Cutover record |
| MIG-007 | Rollback shall remain possible until the agreed point of no return and shall have explicit criteria and owner. | Timed rollback rehearsal |
| MIG-008 | The source platform shall be retained read-only for the approved stabilization and audit period before decommissioning. | Retention and decommission approval |

## 13. Cost and governance requirements

| ID | Requirement | Target/control | Acceptance evidence |
|---|---|---|---|
| FIN-001 | Normal Release 1 Azure consumption shall use the DKK 13,950/month estimated service subtotal plus DKK 1,050/month planning contingency, producing a DKK 15,000/month planning baseline. | Planning baseline | Cost model |
| FIN-002 | The normal-month Azure forecast shall remain within DKK 16,500 unless additional funding is approved. | Authorized envelope | Pre-go-live forecast |
| FIN-003 | Temporary migration and delivery Azure consumption shall be tracked against the DKK 14,000–38,000 allowance. | Separate temporary budget | Migration cost report |
| FIN-004 | Azure costs shall be separated from VAT, labour, third-party transaction fees and licences. | Clear classification | Monthly cost report |
| FIN-005 | Required tags shall identify environment, application, owner, cost centre and data classification where applicable. | Policy compliance | Tag report |
| FIN-006 | Budgets and alerts shall warn before projected or actual spend breaches approved thresholds. | Thresholds in cost plan | Alert test |
| FIN-007 | Cost shall be reviewed monthly and reforecast before major capacity, security, regional or market changes. | Monthly/trigger-based | FinOps review record |
| FIN-008 | Deferred services shall not be added without an ADR, updated cost estimate and named approval. | Change control | ADR and approval |

## 14. AI Operations Assistant requirements

| ID | Requirement | Acceptance evidence |
|---|---|---|
| AI-001 | The assistant shall be released only after core monitoring and security telemetry are accepted. | Delivery gate |
| AI-002 | Access shall be limited to authorized employees and approved operational sources. | Access and source review |
| AI-003 | The assistant shall summarize incidents, exceptions and deployment failures and recommend investigation steps. | Functional evaluation |
| AI-004 | The assistant shall be read-only and shall not deploy, modify resources, execute remediation or activate DR. | Permission and negative tests |
| AI-005 | Inputs shall be minimized/redacted and outputs shall not expose secrets, tokens or unnecessary personal data. | Prompt/output security test |
| AI-006 | Prompts, source access and outputs shall be auditable according to approved retention. | Audit review |
| AI-007 | Failure or unavailability of the assistant shall not affect customer, vendor, order or recovery operations. | Isolation test |

## 15. Assumptions, constraints and dependencies

### Assumptions to validate

- The four server applications can run on Linux App Service after identified readiness changes.
- The relational workload remains suitable for Azure SQL Database General Purpose at the initial 2-vCore sizing.
- Source data quality is sufficient for scripted migration after cleansing and mapping.
- External payment and delivery providers support the required security and reconciliation patterns.
- Stakeholders can provide representatives for UAT, migration validation and cutover approval.

### Fixed Release 1 constraints

- West Europe is active and Sweden Central is warm standby.
- Azure Front Door Standard with custom controls is the approved edge tier.
- Bicep and GitHub Actions with OIDC are the approved delivery technologies.
- Azure OpenAI exists only in West Europe and is non-critical.
- Normal Azure expenditure requires approval beyond DKK 16,500/month.
- Production cutover and DR activation require human authority.

### Deferred capabilities

Front Door Premium, active-active writes, AKS, Terraform, API Management, Service Bus, Redis, Microsoft Sentinel, secondary-region AI and customer-facing generative AI are excluded from Release 1. Their future adoption requires a review trigger, ADR, cost revision and approval.

## 16. Production acceptance gates

Production cutover shall not occur until all mandatory gates pass:

| Gate | Required evidence | Approvers |
|---|---|---|
| Architecture | Bicep deployment matches Final V6 and accepted ADRs | Architecture and Platform owners |
| Application | Functional, integration, UAT, performance and rollback tests pass | Product and Application owners |
| Identity/security | Role/isolation tests, attack tests and risk closure are accepted | Security and Business owners |
| Data/migration | Two rehearsals, reconciliation and rollback evidence are accepted | Data and Business owners |
| Recovery | Restore, regional failover and failback meet RTO/RPO | Operations, Data and Business owners |
| Operations | Monitoring, alerts, runbooks, ownership and responder routing are accepted | Operations owner |
| Cost | Refreshed forecast is within DKK 16,500 or extra funding is approved | Finance and Business owners |
| Cutover | Entry criteria, communications, go/no-go and rollback authority are signed | Business sponsor and Project owner |

## 17. Traceability

| Requirement area | Primary implementation/evidence source |
|---|---|
| Business justification and value | `docs/business/01-business-case.md` |
| Current environment and migration drivers | `docs/business/03-current-environment.md` |
| Architecture and technical response | `docs/architecture/04-target-architecture.md` |
| Migration and cutover | `docs/migration/05-migration-strategy.md` |
| Cost baseline and future estimates | `docs/cost/06-cost-estimation.md` |
| Security risks | `docs/security/07-security-assessment.md` |
| Security controls and attack defence | `docs/security/08-security-strategy.md` |
| Delivery phases and gates | `docs/operations/09-project-roadmap.md` |
| Approved choices and deferred options | `docs/architecture/10-architecture-decisions.md` |

## 18. Change control

The requirements baseline may change only through documented review. Every proposed change shall identify affected requirement IDs, business reason, architecture impact, security/privacy impact, recovery impact, cost change, owner and approver. Approved changes shall update this document and every affected source-of-truth document before implementation proceeds.
