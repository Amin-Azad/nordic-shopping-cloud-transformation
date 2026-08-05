# Nordic Shopping Cloud Transformation — Business Case

| Item | Approved value |
|---|---|
| Company | Nordic Shopping |
| Document | Business Case — Final V6 |
| Owner | Amin Azad |
| Version | Final V6 |
| Status | Planning baseline approved; execution authorization pending. Implementation subject to delivery gates |
| Date | 4 August 2026 |
| First issued (V1, order-of-magnitude approval) | 26 May 2026 |
| Architecture source | `docs/architecture/04-target-architecture.md` |
| Cost source | `docs/cost/06-cost-estimation.md` |
| Normal Azure planning baseline | **DKK 15,000/month**, excluding VAT |
| Authorized Azure operating envelope | **DKK 16,500/month**, excluding VAT |
| Supersedes | All earlier business-case drafts prior to this Final V6 |

## 1. Executive summary

Nordic Shopping is a Copenhagen-based e-commerce marketplace with approximately 35 employees, 40,000 registered customers, 150 active vendors and around 600 orders per day. Its customer, vendor and administration services currently depend on a small on-premises environment in one location. This creates growing risks in availability, recovery, security, scalability, monitoring and software delivery.

### 1.1 How this document relates to the architecture and cost documents

This is not the project's original business case, and its numbers were not produced before the design work — they were produced *from* it. The project ran as a normal planning funnel, not as a single document written once:

| Stage | When | What happened |
|---|---|---|
| Initial business case (V1) | 26 May 2026 | Order-of-magnitude ask, approved before any Azure design existed. It authorized discovery and architecture work under a placeholder DKK 10,000/month ceiling — a planning assumption, not an engineered estimate. |
| Discovery and requirements | 2 June – 9 July 2026 | Current-environment inventory and business/non-functional requirements captured what the platform actually needed to do. |
| Target architecture drafted | 15 June – 3 August 2026 | The Azure design was built, tested against requirements, and iterated through several internal revisions. |
| First real cost estimate | 24 July 2026 | Once a concrete architecture existed, it could finally be priced accurately. This is the point at which the DKK 10,000 ceiling and an even earlier DKK 6,700–7,200 estimate were shown to be understated for the design actually being built. |
| Migration, security and roadmap finalized | 23 July – 1 August 2026 | Delivery plan, controls and cutover approach locked against the stabilized architecture. |
| Architecture decisions consolidated | 3 August 2026 | Sixteen ADRs formalized the accepted design and its alternatives. |
| **This business case (Final V6)** | **4 August 2026** | **Restates the investment ask using the resulting architecture and cost model as evidence, and adds two late resilience decisions (Sweden Central standing capacity, SQL zone redundancy) found during final review.** |

In short: the business case is still the document a decision-maker reads first, and it is still the document that states the ask. It is not, however, the document the numbers were invented in — that would make the ask harder to trust, not easier. The `docs/architecture/04-target-architecture.md` and `docs/cost/06-cost-estimation.md` citations throughout this document mean "verify this figure here," not "this document came first."

The Nordic Shopping Cloud Transformation will modernize the core commerce platform on Microsoft Azure. This is not a server-for-server migration. The approved Release 1 design uses Azure Front Door Standard, managed Linux App Services, Azure SQL geo-replication with a zone-redundant primary, private regional data services, centralized monitoring, automated delivery through Bicep and GitHub Actions, and a two-instance warm-standby disaster-recovery environment that can serve DR traffic without a scale-up delay. West Europe is the active region and Sweden Central is the recovery region.

Every kroner of the estimate below is tied to a specific, named decision, and every deferred capability (Front Door Premium, active-active regions, API Management, Service Bus, Microsoft Sentinel) carries an explicit, measurable trigger for when it should be revisited. The design deliberately does not buy capability the current 35-person, 600-order-per-day scale does not need — but it does not skip resilience that scale does need either: this V6 revision closes the two largest disclosed gaps in the original plan (a single-instance DR standby and a non-zone-redundant primary database) for an added DKK 1,650 per month, which is why the authorized envelope moved from DKK 15,000 to DKK 16,500.

The estimated recurring Azure service consumption is **DKK 13,950 per month**. A **DKK 1,050 planning contingency** produces the normal planning baseline of **DKK 15,000 per month**. The authorized normal-month Azure envelope is **DKK 16,500 per month**, leaving **DKK 1,500** of controlled headroom above the planning baseline. A separate one-time Azure allowance of **DKK 14,000–38,000** covers migration rehearsals, testing, parallel operation and delivery-related consumption.

These figures are planning estimates rather than a Microsoft quotation. They exclude VAT, salaries, external implementation labour, payment-provider charges, Microsoft 365 licensing and other third-party business services. Pricing must be refreshed before procurement and production cutover.

The recommendation is to proceed through the approved 16-week roadmap. Production cutover will occur only after architecture, security, performance, migration, disaster-recovery, operational-readiness and cost gates have objective evidence and named approval.

## 2. Business context

Nordic Shopping provides customer web and mobile shopping, vendor management channels, internal administration and integrations with external payment, notification and delivery providers. The company plans to expand from Denmark into Sweden and Norway.

| Measure | Current baseline | Three-year planning target |
|---|---:|---:|
| Employees | 35 | 80 |
| Registered customers | 40,000 | 250,000 |
| Active vendors | 150 | 800 |
| Daily orders | 600 | 5,000 |
| Markets | Denmark | Denmark, Sweden and Norway |
| Release frequency | Monthly | Weekly or on demand |

Release 1 is sized for the current workload and approved peak tests. It is not assumed to support the three-year target without measured scaling, architecture review and budget reforecasting.

## 3. Business problem

The existing on-premises platform creates the following business risks:

- A site, power, network or major hardware failure can interrupt every digital sales channel.
- Recovery relies on local infrastructure and has no proven regional failover process.
- Capacity increases require procurement, manual configuration and longer lead times.
- Manual infrastructure and application changes can create inconsistent environments and unsafe releases.
- Fragmented monitoring can delay detection and diagnosis of customer-impacting incidents.
- Access, credentials and network controls are difficult to apply and audit consistently.
- Server maintenance consumes time that could support commerce features and vendors.
- The current model cannot confidently support higher transaction volumes or Nordic expansion.

Continuing on premises preserves short-term familiarity but leaves these risks unresolved. Moving the same servers to Azure virtual machines would reduce dependency on the physical site but retain operating-system maintenance, patching, clustering and capacity-management responsibilities.

## 4. Business objectives

The transformation is intended to:

1. Reduce dependency on one physical location.
2. Establish tested recovery with an end-to-end RTO of **60 minutes or less** and RPO of **15 minutes or less**.
3. Achieve at least **99.9% monthly availability** for customer-facing services after production acceptance.
4. Support the current business load and provide a measurable path toward 250,000 customers and 5,000 daily orders.
5. Protect customer, vendor and company data through strong identity, least privilege, private data access and auditable controls.
6. Make infrastructure and application delivery repeatable through Bicep and GitHub Actions using OIDC.
7. Enable weekly or on-demand releases with controlled rollback and minimal customer interruption.
8. Improve incident detection and diagnosis through centralized telemetry, dashboards and actionable alerts.
9. Keep normal Azure consumption within the authorized **DKK 16,500 monthly envelope**.
10. Introduce an employee-only, read-only AI Operations Assistant after the monitoring platform passes acceptance.

These are target outcomes. They are not treated as achieved until implementation and acceptance evidence exist.

## 5. Approved Release 1 solution

The approved solution is a managed Azure PaaS modular monolith. The Nordic API remains the sole production business-logic and data-access boundary.

| Capability | Approved design |
|---|---|
| Regional model | West Europe active; Sweden Central warm standby |
| Public ingress | Azure Front Door Standard with TLS, health probes, priority routing and custom WAF/rate-limit rules |
| Applications | Customer Web, Nordic API, Vendor Portal and Admin Portal as separate Linux App Services in each region |
| Compute | One P1v3 plan per region; two active workers in West Europe and two standing standby workers in Sweden Central, with no scale-up delay before serving DR traffic |
| Database | Azure SQL Database General Purpose, provisioned 2 vCores, with failover group and controlled promotion |
| Object data | Private StorageV2 account in each region with replication for selected critical blobs |
| Identity | Entra External ID for customers; B2B/workforce identity for vendors and employees; managed identities for workloads |
| Secrets | Separate private Key Vault in each region |
| Networking | Regional VNets, delegated integration subnets, private-endpoint subnets and Private DNS |
| Delivery | Bicep and GitHub Actions with OIDC, staging slots, validation and approved slot swaps |
| Operations | Application Insights, Log Analytics, Azure Monitor alerts, action groups and workbooks |
| AI | West Europe employee-only, read-only Operations Assistant; advisory and non-critical |
| Recovery authority | Named people declare a disaster and authorize traffic activation; CI/CD cannot activate DR |

Azure OpenAI is deployed only in West Europe. Consequently, West Europe uses private DNS and private endpoints for SQL, Blob, Key Vault and Azure OpenAI, while Sweden Central uses them for SQL, Blob and Key Vault only.

## 6. Scope

### 6.1 In scope

- Cloud-readiness changes for Customer Web, Nordic API, Vendor Portal and Admin Portal
- Production hosting in West Europe and warm standby in Sweden Central
- Migration of approved SQL data and application files
- Customer, vendor, workforce and workload identity integration
- API-side role, ownership, action and vendor-isolation authorization
- Private data services, regional networking and App Service origin restrictions
- Bicep modules and GitHub Actions pipelines with security and approval gates
- Central logging, monitoring, alerts and operational dashboards
- Backup, restore, two migration rehearsals, regional failover and failback testing
- Security implementation, attack-defence validation and incident runbooks
- Governance, tagging, budgets, alerts and monthly cost review
- Employee-only, read-only AI Operations Assistant after monitoring acceptance
- Training, ownership, documentation and operational handover

### 6.2 Out of scope for Release 1

- Full application replacement or microservices conversion
- Active-active database writes
- Hosting mobile applications as Azure server workloads; they remain API clients
- Redesign of payment, courier or vendor-owned platforms
- Migration of unrelated corporate systems, end-user devices or Microsoft 365
- Front Door Premium, API Management, Service Bus, Redis, AKS and virtual machines
- Microsoft Sentinel, a continuously staffed SOC or managed operations service
- Customer-facing generative AI or autonomous production actions
- Guaranteed capacity for the three-year target without later scaling decisions

## 7. Options considered

| Option | Business assessment | Decision |
|---|---|---|
| Continue on premises | Lowest immediate change, but retains single-site, scaling, delivery and recovery risk | Rejected |
| Lift and shift to Azure VMs | Removes physical-site dependency but preserves patching, clustering and server-management effort | Rejected |
| AKS and microservices redesign | Powerful but adds cost, skills demand and delivery complexity beyond current need | Rejected for Release 1 |
| Active-active multi-region | Stronger continuous regional service but significantly increases data consistency, testing and operating complexity | Deferred |
| Managed Azure PaaS with warm standby | Balances resilience, security, delivery capability, operating effort and cost | Approved |

Front Door Premium was evaluated but is not the approved Release 1 target. Front Door Standard was selected with custom WAF controls, rate limiting, origin lockdown, application security and monitoring. Premium becomes a future option when managed WAF/bot capabilities, private origins, compliance or materially higher attack risk justify the added cost.

## 8. Expected business value

| Value area | Expected outcome | Required evidence |
|---|---|---|
| Revenue protection | Lower exposure to a single-site outage | Availability reporting and successful regional recovery exercise |
| Growth readiness | Capacity can scale from measured demand without physical procurement | Load-test results, autoscale evidence and capacity reviews |
| Delivery speed | Repeatable weekly or on-demand releases | Pipeline history, slot-swap validation and rollback evidence |
| Security | Central identity, private data services, least privilege and tested attack controls | Access reviews, policy results and security-test report |
| Operations | Faster detection, diagnosis and escalation | Alert tests, responder routing and MTTD/MTTR reporting |
| Recovery | Controlled restore, failover and failback | Timed exercises meeting RTO and RPO |
| Cost control | Transparent consumption and trigger-based growth decisions | Budgets, monthly forecast and variance review |
| Team capability | Reduced server maintenance and clearer accountability | Runbooks, training and operational acceptance |

No direct revenue uplift or labour saving is claimed because validated outage-loss, conversion and staffing data have not been supplied. Benefits will be measured after implementation through avoided downtime, release performance, incident effort, cost per completed order and budget variance.

## 9. Financial case

### 9.1 Release 1 Azure operating estimate

| Financial measure | Estimate | Purpose |
|---|---:|---|
| Azure service-consumption subtotal | DKK 13,950/month | Estimated resources in the approved architecture under normal assumptions |
| Planning contingency | DKK 1,050/month | Usage, telemetry, currency and estimation variation |
| **Normal-operation planning baseline** | **DKK 15,000/month** | Authoritative monthly planning figure |
| **Authorized operating envelope** | **DKK 16,500/month** | Maximum normal recurring Azure spend without further approval |
| Controlled headroom | DKK 1,500/month | Moderate traffic, telemetry and consumption variation |
| Annual planning baseline | DKK 180,000/year | Twelve months at DKK 15,000 |
| Annual authorized envelope | DKK 198,000/year | Twelve months at DKK 16,500 |

### 9.2 Temporary delivery estimate

| Cost item | Estimate | Treatment |
|---|---:|---|
| Migration, testing and delivery-related Azure consumption | DKK 14,000–38,000 one time | Separate from the recurring operating budget |
| Seasonal peak month | DKK 15,500–18,000 | Requires forecast and temporary approval when above the normal envelope |
| Declared-DR operation | Variable | Recorded and approved as incident-related exceptional consumption |

### 9.3 Exclusions and financial controls

The estimate excludes VAT, salaries, external implementation labour, Microsoft 365, payment-provider charges, SMS, maps, courier services and other third-party licences. Azure prices, currency conversion and usage assumptions must be refreshed in the Azure Pricing Calculator before procurement and cutover.

Cost Management budgets will notify responsible owners at 50%, 70%, 85%, 95% and 100% of actual monthly spend, at 90% forecast as an early warning, and at 110% forecast as a formal capacity and budget review trigger. Budgets provide alerts; they do not automatically stop production services.

## 10. Future cost estimation

Future figures are conditional planning ranges, not approved budgets.

| Stage | Expected architecture position | Monthly estimate | Annualized estimate |
|---|---|---:|---:|
| Release 1 | Shared regional plans, 2-vCore SQL pair and warm standby | DKK 15,000 | DKK 180,000 |
| Year 1 upper envelope | Normal variation within existing authorization | Up to DKK 16,500 | Up to DKK 198,000 |
| Year 2 growth | More compute/SQL capacity and higher traffic and telemetry | DKK 16,000–21,000 | DKK 192,000–252,000 |
| Three-year target | Dedicated API capacity, larger data tier and expanded integration/security | DKK 22,000–28,000 | DKK 264,000–336,000 |
| Five-year Nordic expansion | More independent plans, larger data platform and mature security operations | DKK 38,000–55,000 | DKK 456,000–660,000 |

The bill will grow in steps when measured demand justifies an additional plan, database tier or platform service. It will not increase directly in proportion to registered-customer count.

Possible future additions include Front Door Premium, separate API plans, API Management, Service Bus, Redis, Microsoft Sentinel, a Sweden Central AI deployment and an active-active operating model. Every addition requires a measured trigger, updated architecture decision, security and recovery review, new cost estimate and business approval.

## 11. Delivery approach and decision gates

The project follows the approved 16-week roadmap defined in `docs/operations/09-project-roadmap.md`:

0. Mobilization
1. Engineering foundation
2. Core Azure platform
3. Application and CI/CD
4. Security and observability
5. Migration rehearsal
6. DR and operational readiness
7. Production cutover
8. Stabilization and optimization

Documentation completion does not mean that migration or business outcomes are complete. Each phase must produce evidence and pass its gate before the next risk-bearing step proceeds.

## 12. Principal risks and treatment

| Risk | Potential business effect | Treatment |
|---|---|---|
| Application needs more modernization than expected | Delay and additional cost | Early dependency assessment, proof of concept and reapproval before build |
| Shared regional compute creates contention | Slow or unavailable channels | Per-app telemetry, load tests, autoscale and trigger to separate plans |
| Asynchronous replication loses recent writes | Order or payment inconsistency | RPO monitoring, idempotency, outbox/reconciliation and authorized failover |
| Identity migration disrupts access | Lost sales or support workload | Pilot cohorts, role mapping, negative tests and rollback procedure |
| Third-party provider failure | Delayed or duplicated commerce activity | Timeouts, retries, signed webhooks, idempotency and reconciliation |
| Security attack or control failure | Fraud, data loss or outage | Defence-in-depth controls, testing, monitoring and response playbooks |
| Migration reconciliation fails | Incorrect production records | Two rehearsals, counts, checksums, business validation and rollback gate |
| Consumption exceeds forecast | Budget breach | Budget alerts, telemetry controls, monthly review and reforecast triggers |
| Team is not operationally ready | Longer incidents and unsafe changes | Runbooks, training, named owners and operational acceptance |
| AI produces unsafe advice or exposes data | Bad decisions or confidentiality breach | Approved sources, redaction, read-only access, audit and human judgment |

## 13. Success measures

| Measure | Acceptance target |
|---|---|
| Availability | At least 99.9% monthly for accepted customer-facing production services |
| Recovery | Timed exercise demonstrates RTO ≤ 60 minutes and RPO ≤ 15 minutes |
| Performance | Approved Release 1 workload and response-time tests pass |
| Security | No unresolved critical finding; high risks remediated or formally accepted |
| Authorization | Customer, vendor, employee and workload tests pass, including cross-vendor negative tests |
| Delivery | Repeatable Bicep deployments and controlled slot-based releases demonstrated |
| Migration | Reconciliation, cutover and rollback evidence accepted after rehearsals |
| Operations | Dashboards, alerts, runbooks, routing, ownership and on-call tests accepted |
| Cost | Refreshed normal-month forecast remains within DKK 16,500 or additional funding is approved |
| Handover | Business, technical, security, data and operations owners sign off |

## 14. Governance and authority

- The Final V6 target architecture and its 16 accepted Architecture Decision Records govern Release 1.
- Changes affecting ingress, identity, data access, regional recovery, security or budget require formal review.
- Deferred capabilities cannot enter Release 1 without an ADR, cost update and security/recovery impact assessment.
- GitHub Actions may deploy approved infrastructure and applications but cannot declare a disaster, approve possible data loss or activate DR traffic.
- Production cutover, SQL promotion, Front Door DR activation and failback require named human authorization.
- The authoritative financial details remain in `docs/cost/06-cost-estimation.md`; this business case summarizes the investment decision.

## 15. Recommendation and approval requested

Approve continued implementation of the Nordic Shopping Cloud Transformation using the Final V6 target architecture and the 16-week delivery roadmap.

The decision authorizes:

- the approved Release 1 architecture;
- normal Azure planning at DKK 15,000 per month;
- recurring Azure consumption up to DKK 16,500 per normal month without further approval; and
- a separate DKK 14,000–38,000 one-time Azure allowance for migration, testing and delivery activities.

This approval does not authorize production cutover. Cutover remains conditional on objective evidence that the business requirements, security controls, performance targets, migration reconciliation, recovery objectives, operating model and refreshed cost forecast have passed their approval gates.
