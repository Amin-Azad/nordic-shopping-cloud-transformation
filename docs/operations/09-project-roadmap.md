# Nordic Shopping Cloud Transformation — Project Roadmap

| Item | Approved value |
|---|---|
| Company | Nordic Shopping |
| Document | Project Roadmap |
| Owner | Amin Azad |
| Version | Final V6 |
| Status | Delivery baseline |
| Date | 4 August 2026 |
| Planned delivery window | 16 weeks after project approval |
| Primary region | West Europe (`westeurope`) |
| DR region | Sweden Central (`swedencentral`) |
| Authorized operating envelope | DKK 16,500/month (planning baseline DKK 15,000/month) |
| Related documents | Business case, target architecture, migration strategy, cost model, security assessment and security strategy |

## 1. Purpose

This roadmap converts the approved Nordic Shopping cloud design into an executable delivery plan. It defines the order of work, dependencies, owners, deliverables, quality gates and evidence required to move from planning to a secure production service.

The roadmap is intentionally gate-driven. Completing a task or deploying an Azure resource does not automatically approve the next phase. Each phase must produce evidence and receive the required technical or business approval.

## 2. Current position

The project has completed the main planning and architecture work over a roughly ten-week planning phase (26 May – 4 August 2026). No production migration is considered complete yet, and the 16-week execution roadmap below starts only after this document set receives final approval.

| Workstream | Completed | Current status | Evidence |
|---|---|---|---|
| Business case (initial, order-of-magnitude) | 26 May 2026 | Superseded by V6 reapproval | `docs/business/01-business-case.md` Section 1.1 |
| Business requirements | 9 June 2026 | Complete | Approved requirements baseline |
| Current-state assessment | 2 June 2026 | Complete at planning level | Application, data and dependency inventory |
| Target architecture | 15 June – 4 August 2026 | Complete | Final target design and diagram set, revised through V6 |
| Migration strategy | 23 July 2026 | Complete | Phased re-platform plan with rehearsal and cutover controls |
| Cost model | 24 July – 4 August 2026 | Complete | Present, peak, three-year and five-year forecasts; revised for V6 resilience decisions |
| Security assessment | 28 July 2026 | Complete | Risk register (S01–S16) |
| Security strategy | 30 July – 4 August 2026 | Complete | Technical controls, attack-defence model and risk traceability |
| Architecture decisions (ADRs) | 3–4 August 2026 | Complete | Sixteen accepted ADRs, two amended for V6 |
| Business case (final reapproval) | 4 August 2026 | Complete — pending approval to proceed | `docs/business/01-business-case.md` |
| Infrastructure as code | Not started | Not started | Bicep code and deployment evidence required |
| CI/CD implementation | Not started | Not started | GitHub Actions and OIDC evidence required |
| Application cloud readiness | Not started | Not started | Code, configuration and test evidence required |
| Data migration | Not started | Not started | Rehearsal and reconciliation evidence required |
| Production cutover | Not started | Not started | Go-live approval required |

## 3. Delivery objectives

The project will deliver:

- A managed Azure PaaS platform with West Europe active and Sweden Central warm standby.
- Four separately deployed applications: Customer Web, Nordic API, Vendor Portal and Admin Portal.
- Azure Front Door Standard, custom WAF rules and locked-down App Service origins.
- Private SQL, Blob Storage, Key Vault and West Europe Azure OpenAI access.
- Entra External ID for customers, B2B for vendors and workforce identity for employees.
- Bicep-based repeatable infrastructure and GitHub Actions using OIDC.
- Central monitoring, alerting, security telemetry and operational dashboards.
- A tested migration, rollback, regional failover and failback process.
- A read-only AI Operations Assistant after monitoring acceptance.
- Operational documents and portfolio evidence that reflect the implemented system.

## 4. Delivery principles

1. Build reusable platform foundations before deploying business workloads.
2. Use Bicep for Azure infrastructure and protected pipelines for deployment.
3. Promote the same immutable application artifact through environments and regions.
4. Test private connectivity and identity authorization separately.
5. Migrate data through rehearsed, measurable and reversible procedures.
6. Introduce production traffic gradually and retain a tested rollback path.
7. Treat security, observability, cost and recovery as release requirements.
8. Record real test results; do not present architecture objectives as achieved outcomes.

## 5. Sixteen-week implementation roadmap

The week numbers begin after business approval, funding and access are available. Calendar dates may move, but phase gates and dependencies must remain.

| Phase | Weeks | Main outcome | Exit gate |
|---|---:|---|---|
| 0. Mobilization | 1 | Scope, ownership and delivery controls approved | Project kickoff gate |
| 1. Engineering foundation | 2–3 | Repository, Bicep structure, environments and OIDC ready | Foundation gate |
| 2. Core Azure platform | 4–5 | Network, identity, data and shared services deployed | Platform gate |
| 3. Application and CI/CD | 6–8 | Four workloads deploy safely through staging | Release gate |
| 4. Security and observability | 9–10 | Controls, logs, alerts and dashboards validated | Security gate |
| 5. Migration rehearsal | 11–12 | Repeatable data and application migration proven | Migration-readiness gate |
| 6. DR and operational readiness | 13 | Failover, recovery and runbooks tested | Operational gate |
| 7. Production cutover | 14 | Controlled migration and traffic activation | Go-live gate |
| 8. Stabilization and optimization | 15–16 | Service stabilized, tuned and handed over | Project-closure gate |

## 6. Phase 0 — Mobilization

**Duration:** Week 1

### Activities

- Confirm scope, assumptions, exclusions and success measures.
- Approve the DKK 16,500 authorized monthly operating envelope and cost-alert recipients.
- Name the business sponsor, product owner, platform owner, security owner, data owner, application owner, incident commander and DR owner.
- Confirm Azure tenant, subscriptions, billing scope, GitHub organization and domain ownership.
- Establish change control, risk review, decision logging and weekly reporting.
- Freeze superseded documents and adopt the final architecture as the implementation baseline.
- Confirm third-party provider contacts, test environments and migration blackout periods.

### Deliverables

- Project charter and responsibility matrix.
- Approved scope, schedule and budget baseline.
- Risk, issue, dependency and decision registers.
- Environment and access request list.
- Initial migration communications plan.

### Exit criteria

- Required owners accept their responsibilities.
- Funding, Azure access, GitHub access and test-provider access are available.
- Critical assumptions have an owner and validation date.
- No unresolved scope issue prevents foundation work.

## 7. Phase 1 — Engineering foundation

**Duration:** Weeks 2–3

### Activities

- Create the repository structure for `infra`, applications, workflows, tests and operational documentation.
- Build reusable Bicep modules and environment parameter files.
- Implement naming, tagging, resource-group and diagnostic-setting conventions.
- Configure GitHub branch protection, CODEOWNERS and protected environments.
- Create separate federated identities for infrastructure and application deployment.
- Restrict OIDC trust by organization, repository, branch or protected environment.
- Add Bicep linting, validation, `what-if`, unit tests, dependency scanning and secret scanning.
- Define development, test and production configuration handling without committing secrets.

### Deliverables

- Bicep module skeleton and environment orchestration.
- Infrastructure validation workflow.
- Application build and test workflow.
- GitHub OIDC configuration with no stored Azure client secret.
- Coding, branching and release standards.

### Exit criteria

- A test deployment can authenticate with OIDC and deploy only within its approved scope.
- Pull requests cannot bypass required review and automated checks.
- Bicep validation and `what-if` complete successfully.
- Secret scanning confirms no credentials are stored in the repository.

## 8. Phase 2 — Core Azure platform

**Duration:** Weeks 4–5

### Activities

- Deploy shared resource groups, tags, budgets, policies and diagnostic settings.
- Deploy West Europe and Sweden Central VNets with separate integration and private-endpoint subnets.
- Deploy regional App Service plans, applications and staging slots.
- Deploy Azure SQL primary, geo-secondary and failover group.
- Deploy regional Storage accounts and approved critical-blob object replication.
- Deploy independent regional Key Vaults and controlled DR secret provisioning.
- Deploy West Europe Azure OpenAI and its private endpoint.
- Configure Private DNS: four service zones in West Europe and three required service zones in Sweden Central.
- Deploy Front Door, custom domains, routes, origin groups, health probes and WAF policy.
- Configure managed identities, minimum data-plane access and App Service origin restrictions.

### Deliverables

- Repeatable development/test platform deployment.
- Production-like West Europe and Sweden Central platform.
- Resource inventory and generated deployment outputs.
- Private DNS, connectivity and identity-access test results.
- Initial cost-versus-model comparison.

### Exit criteria

- Bicep deployment is repeatable and shows no unexplained drift.
- SQL, Storage, Key Vault and Azure OpenAI public access is disabled as designed.
- The API resolves approved services to private IP addresses.
- Portals have no direct permissions to business data services.
- Direct origin requests are denied while valid Front Door traffic succeeds.
- Actual platform cost remains within the approved tolerance.

## 9. Phase 3 — Application modernization and CI/CD

**Duration:** Weeks 6–8

### Activities

- Externalize application configuration and remove local durable state.
- Implement health endpoints, structured logging, correlation IDs and dependency telemetry.
- Integrate External ID, B2B and workforce authentication.
- Implement API-side role, action, ownership and vendor-isolation authorization.
- Replace data-service credentials with managed identity.
- Implement parameterized SQL access, safe error handling, idempotency and provider resilience.
- Implement signed webhook validation, timestamp checks, replay prevention and reconciliation.
- Implement upload quarantine, malware scanning and promotion to trusted storage.
- Build immutable artifacts and deploy them to both regional staging slots.
- Run warm-up and smoke tests, then require human approval before production slot swaps.
- Keep Sweden Central application versions aligned without activating DR traffic.

### Deliverables

- Cloud-ready versions of all four applications.
- Automated unit, integration, authorization and smoke tests.
- Application deployment workflow with staging evidence and approval.
- Rollback and database-change compatibility procedure.
- Provider integration test evidence.

### Exit criteria

- The same artifact deploys successfully to both regions.
- Staging tests pass before a production approval can be issued.
- Cross-vendor and unauthorized-access tests fail securely.
- Slot swap and compatible swap-back are demonstrated.
- CI/CD cannot activate Front Door DR traffic.

## 10. Phase 4 — Security and observability

**Duration:** Weeks 9–10

### Activities

- Tune WAF custom rules in detection mode and move approved rules to prevention.
- Enforce MFA, Conditional Access, privileged access and group-based RBAC.
- Enable application, Front Door, Entra, SQL, Key Vault, Storage, Activity Log and deployment telemetry.
- Configure Application Insights, Log Analytics, Azure Monitor alerts, Action Groups and workbooks.
- Configure Defender for Cloud recommendations selected for the production risk profile.
- Run SAST, dependency, secret, infrastructure and dynamic application security tests.
- Test credential stuffing, origin bypass, IDOR/BOLA, SQL injection, XSS, CSRF, API abuse, forged webhooks, malicious uploads and excessive privilege.
- Validate incident alert routing, evidence retention and responder acknowledgement.
- Correct or formally accept every security finding before go-live.

### Deliverables

- Implemented security-control baseline.
- Monitoring dashboard and alert catalogue.
- Security test report and remediation record.
- Access review and privileged-role evidence.
- Go-live control-verification matrix.

### Exit criteria

- No unresolved critical or high-risk finding remains without executive acceptance.
- Required logs are searchable and contain correlation data without exposed secrets.
- Critical alerts reach both primary and secondary responders.
- Direct-origin, cross-vendor and unauthorized data-access tests are blocked.
- WAF prevention rules meet agreed false-positive and coverage thresholds.

## 11. Phase 5 — Migration rehearsal

**Duration:** Weeks 11–12

### Activities

- Clean and map source data to the target schema.
- Define full-load and delta-load procedures with encryption and restricted staging.
- Rehearse database migration in a production-like environment.
- Rehearse approved Blob migration and verify checksums, counts and metadata.
- Test identity migration or account transition procedures.
- Execute application functional, integration, performance and user-acceptance tests.
- Measure migration duration, final synchronization window and expected downtime.
- Rehearse rollback to the on-premises platform.
- Finalize customer, vendor, employee and support communications.

### Deliverables

- Version-controlled migration scripts and operating procedure.
- Rehearsal report with timing, defects and improvements.
- Reconciliation report for records, totals, files and critical business transactions.
- Signed user-acceptance result.
- Final cutover and rollback plan.

### Exit criteria

- Two successful rehearsals are completed without unresolved data loss or corruption.
- Reconciliation meets the approved accuracy threshold.
- Performance meets the agreed baseline under production-like load.
- The measured outage fits the approved business window.
- Rollback remains achievable within the decision window.

## 12. Phase 6 — DR and operational readiness

**Duration:** Week 13

### Activities

- Simulate a West Europe outage and declare an incident.
- Confirm human authorization before DR activation.
- Promote the SQL secondary, validate Blob availability and confirm regional secrets.
- Verify Sweden Central's standing two-worker capacity and application health before activating DR traffic.
- Validate identity, private DNS, permissions, provider access and security controls.
- Activate Front Door standby origins and execute business smoke tests.
- Measure achieved RPO and RTO.
- Reconcile data and test controlled failback.
- Run incident, security, backup-restore and operational tabletop exercises.
- Finalize runbooks, escalation contacts, dashboards and support handover.

### Deliverables

- DR exercise and failback report.
- Measured RPO/RTO evidence.
- Incident response, DR, backup and deployment runbooks.
- On-call and escalation matrix.
- Operational-readiness checklist.

### Exit criteria

- RPO is no more than 15 minutes and RTO is no more than 60 minutes, or the business formally accepts revised objectives.
- CI/CD is proven unable to authorize DR traffic activation.
- Backup restore and regional failover are both tested; neither is treated as a substitute for the other.
- Operations and security owners approve production readiness.

## 13. Phase 7 — Production cutover

**Duration:** Week 14

### Pre-cutover decision

The change authority reviews migration, security, performance, cost, DR, rollback and business-readiness evidence. Go-live proceeds only when all mandatory gates are green.

### Cutover sequence

1. Confirm owners, support coverage, backups and rollback checkpoint.
2. Announce the change window and place the source system into the approved write-control state.
3. Execute the final data delta and reconciliation.
4. Validate identity, API, orders, payments, vendors, administration and provider integrations.
5. Enable West Europe production origins and gradually shift public traffic through Front Door.
6. Monitor application, dependency, security and business metrics.
7. Obtain business confirmation and close the rollback window only after stable operation.

### Exit criteria

- Critical customer and vendor journeys work correctly.
- Data reconciliation is approved by the data and business owners.
- No critical security, availability or financial alert is unresolved.
- Rollback is executed if a pre-agreed stop condition is reached.
- The business sponsor authorizes continued production operation.

## 14. Phase 8 — Stabilization and optimization

**Duration:** Weeks 15–16

### Activities

- Operate enhanced monitoring and daily defect, risk and cost reviews.
- Tune autoscale, SQL capacity, WAF thresholds, logging volume and alert noise.
- Correct deployment, application and operational defects.
- Validate Azure invoices against the DKK 15,000 planning baseline and DKK 16,500 approved budget.
- Complete knowledge transfer and assign business-as-usual ownership.
- Enable the read-only AI Operations Assistant after monitoring data quality and security gates pass.
- Create the final architecture-as-built record and portfolio demonstration.
- Capture lessons learned and update the improvement backlog.

### Deliverables

- Stabilization report and outstanding backlog.
- Cost-optimization report.
- Architecture-as-built document.
- Support acceptance and project-closure report.
- Portfolio README, screenshots, diagrams and demonstration evidence with sensitive data removed.

### Exit criteria

- Service levels and error rates remain stable for the agreed observation period.
- Actual cost is understood and approved.
- All operational controls have a named long-term owner.
- Remaining risks are recorded, prioritized and accepted.
- Project closure is approved by the sponsor.

## 15. Workstream ownership

One person may perform several roles in a portfolio implementation, but the responsibilities remain separate and approvals must still be recorded.

| Workstream | Accountable owner | Supporting roles |
|---|---|---|
| Scope, value and go-live | Business sponsor | Product owner, project lead |
| Architecture and Bicep | Platform owner | Security and application owners |
| Application modernization | Application owner | Developers, QA, platform owner |
| Identity and access | Identity owner | Security and application owners |
| Data migration | Data owner | Database engineer, application owner |
| Security assurance | Security owner | Identity, platform and application owners |
| CI/CD and releases | DevOps owner | Platform and application owners |
| Monitoring and support | Operations owner | Application, security and platform owners |
| Disaster recovery | DR owner | Incident commander, data and platform owners |
| Cost governance | FinOps owner | Sponsor and platform owner |

## 16. Mandatory delivery gates

| Gate | Required evidence | Approvers |
|---|---|---|
| G1 — Project kickoff | Scope, owners, budget, access and risks | Sponsor, project lead |
| G2 — Foundation | OIDC, protected repository, Bicep validation | Platform, DevOps, security |
| G3 — Platform | Repeatable deployment, private access and cost check | Architecture, platform, security |
| G4 — Release | Staging, smoke tests, authorization tests and rollback | Application, QA, DevOps |
| G5 — Security | Threat tests, access reviews, logging and remediation | Security, risk owner |
| G6 — Migration readiness | Two rehearsals, reconciliation, UAT and rollback | Data, application, business |
| G7 — Operational readiness | DR, restore, monitoring, runbooks and support | Operations, security, DR owner |
| G8 — Go-live | All mandatory gates green and change approved | Sponsor, change authority |
| G9 — Closure | Stable service, cost review, handover and residual risks | Sponsor, operations |

## 17. Success measures

| Area | Target |
|---|---|
| Infrastructure deployment | Repeatable Bicep deployment with no unexplained drift |
| Release quality | Staging and smoke tests pass before every production approval |
| Security | No unresolved unaccepted critical/high finding at go-live |
| Origin protection | Direct App Service origin and unauthorized SCM requests denied |
| Vendor isolation | All cross-vendor negative tests blocked and logged |
| Recovery point | RPO no more than 15 minutes in the DR exercise |
| Recovery time | RTO no more than 60 minutes in the DR exercise |
| Data migration | Reconciled record, financial and file counts meet business threshold |
| Availability | Measured against the agreed service objective after go-live |
| Cost | Normal production operation within the approved DKK 16,500 budget unless formally revised |
| Operations | Critical alerts acknowledged within the agreed response time |
| Documentation | As-built architecture, runbooks and decision records match the deployed system |

## 18. Main dependencies

| Dependency | Required by | Owner response |
|---|---|---|
| Azure subscription and budget approval | Week 1 | Sponsor and FinOps owner |
| Domain and DNS control | Front Door deployment | Business/platform owner |
| Entra tenants, licences and administrators | Identity implementation | Identity owner |
| GitHub organization and protected environments | CI/CD foundation | DevOps owner |
| Source-system access and data quality | Migration rehearsal | Data owner |
| Payment, email, SMS and delivery sandboxes | Integration testing | Product/application owner |
| Maintenance window and business communications | Cutover | Sponsor and product owner |
| Security testing capacity | Security gate | Security owner |
| Operations and escalation coverage | DR test and go-live | Operations owner |

## 19. Key schedule risks and responses

| Risk | Schedule effect | Response |
|---|---|---|
| Incomplete source inventory | Rework during migration | Validate dependencies in Week 1 and maintain discovery backlog |
| Application depends on local state | Cloud-readiness delay | Identify early; move state to approved managed services |
| Poor source-data quality | Failed reconciliation | Profile, cleanse and assign business rules before rehearsal |
| Identity/licensing decisions delayed | Authentication blocked | Confirm tenants, External ID and B2B design during mobilization |
| Provider sandboxes unavailable | Incomplete end-to-end tests | Use contract tests and secure simulators; do not waive production validation |
| Security findings discovered late | Go-live delay | Shift automated testing into foundation and application phases |
| P1v3 or SQL capacity insufficient | Performance gate failure | Load test and resize before cutover; update cost approval |
| WAF false positives | Customer/provider traffic blocked | Tune in detection mode using representative traffic |
| DR secret or dependency missing | Failover failure | Maintain regional checklist and test before activation |
| Cost exceeds forecast | Budget breach | Use alerts, weekly cost review and capacity/logging optimization |

## 20. Cost checkpoints

| Checkpoint | Financial action |
|---|---|
| Mobilization | Approve DKK 16,500 normal-month production budget |
| Platform deployment | Compare deployed SKUs and forecasts with the cost model |
| Load testing | Record temporary scaling and test-environment cost |
| Pre-go-live | Re-run Azure pricing estimate using final configuration |
| First production week | Review daily spend and unexpected ingestion/egress |
| End of stabilization | Establish the business-as-usual cost baseline |
| Quarterly | Reforecast capacity, commitments and growth triggers |

Temporary migration, testing and DR exercises may create costs above the normal monthly baseline. These costs require a time-bounded allowance and must not silently become permanent capacity.

## 21. Post-launch roadmap

These are trigger-based improvements, not release-1 promises.

| Trigger | Future change |
|---|---|
| Sustained edge attacks or need for managed bot/WAF rules | Upgrade Front Door Standard to Premium |
| Need for API products, quotas or partner lifecycle | Introduce Azure API Management |
| Slow or unreliable synchronous workflows | Introduce Service Bus and background processing |
| Repeated high-read pressure | Evaluate Redis caching and read optimization |
| Compliance requires inspected/allow-listed egress | Add Azure Firewall or NAT Gateway design |
| Regional load becomes continuous and business-critical | Review active-active application strategy |
| SQL limits or workload pattern materially change | Reassess database tier, partitioning or architecture |
| Monitoring volume grows beyond forecast | Adjust sampling, retention and archive policy |
| AI assistant proves safe and valuable | Add approved capabilities through human-controlled workflows |
| Nordic market expansion | Reassess regions, data residency, latency and cost model |

## 22. Reporting cadence

| Cadence | Review |
|---|---|
| Daily during cutover/stabilization | Incidents, defects, business journeys, security and cost |
| Weekly during delivery | Milestones, risks, decisions, spend and gate readiness |
| At every phase gate | Evidence, exceptions and formal approval |
| Monthly after launch | Availability, incidents, security, capacity and cost |
| Quarterly after launch | Access, DR readiness, architecture decisions and growth forecast |

## 23. Definition of project complete

The cloud transformation is complete only when:

- The approved infrastructure and applications are deployed through controlled pipelines.
- Production data is migrated and reconciled.
- Security, performance, recovery and cost gates have passed.
- Customer, vendor and employee journeys operate successfully.
- Monitoring, incident response, backup, DR and support processes are accepted.
- The as-built architecture and architecture-decision records match reality.
- Residual risks and future improvements have owners and review dates.
- The business sponsor signs the project-closure decision.

Planning documents and diagrams alone do not satisfy this definition.
