# Nordic Shopping Cloud Transformation — Cost Estimation

| Item | Approved value |
|---|---|
| Company | Nordic Shopping |
| Document | Cost Estimation |
| Owner | Amin Azad |
| Version | Final V6 |
| Status | Authoritative financial planning baseline |
| Estimate date | 4 August 2026 |
| First issued | 24 July 2026 |
| Currency | Danish kroner (DKK), excluding VAT |
| Architecture source | `docs/architecture/04-target-architecture.md` |
| Normal-operation estimate | **DKK 15,000/month** |
| Authorized normal-month envelope | **DKK 16,500/month** |
| Supersedes | the earlier cost analysis and all previous cost drafts |

## 1. Purpose

This document estimates the Azure cost of the exact Release 1 architecture approved for Nordic Shopping. It also estimates temporary migration costs, seasonal and disaster-recovery exposure, and the likely cost of future growth.

It is a planning estimate, not a Microsoft quotation. Actual invoices depend on regional prices, contractual discounts, currency conversion and measured consumption. The configuration must be recreated in the Azure Pricing Calculator before procurement and refreshed before production cutover.

## 2. Executive decision

| Financial view | Estimate |
|---|---:|
| Azure operating subtotal | DKK 13,950/month |
| Planning contingency | DKK 1,050/month |
| **Normal-operation planning baseline** | **DKK 15,000/month** |
| **Normal-operation budget authorization** | **DKK 16,500/month** |
| Annual planning baseline | DKK 180,000/year |
| Annual authorized envelope | DKK 198,000/year |
| One-time Azure delivery and migration allowance | DKK 14,000–38,000 |
| Seasonal peak month | DKK 15,500–18,000 |
| Three-year operating estimate | DKK 22,000–28,000/month |
| Five-year Nordic expansion estimate | DKK 38,000–55,000/month |

The former DKK 10,000 ceiling and DKK 6,700–7,200 estimate are obsolete for the approved architecture. They were produced before the final compute, SQL geo-secondary, WAF, private connectivity, security monitoring and warm-standby requirements were reconciled.

## 3. Architecture being estimated

This estimate does not introduce a cheaper or different architecture. It prices the Final V6 design:

- West Europe active and Sweden Central warm standby.
- Azure Front Door Standard with WAF custom rules and origin lockdown.
- Customer Web, Nordic API, Vendor Portal and Admin Portal as separate Linux App Services in each region.
- One shared, zone-redundant P1v3 plan per region: two West Europe workers and two standing Sweden Central standby workers, with no scale-up delay before serving DR traffic.
- One staging slot per application in each region; slots share their regional plan capacity.
- Azure SQL Database General Purpose, provisioned 2 vCores, with an equal-size geo-secondary and failover group.
- One Storage account and one Key Vault per region.
- Seven private endpoints: SQL, Blob, Key Vault and Azure OpenAI in West Europe; SQL, Blob and Key Vault in Sweden Central.
- Four Private DNS zones linked in West Europe and three in Sweden Central.
- Application Insights, Log Analytics, Azure Monitor alerts, selected Defender coverage and Blob upload malware scanning.
- A bounded, employee-only Azure OpenAI Operations Assistant in West Europe.
- Bicep and GitHub Actions using OIDC.

Front Door Premium, API Management, Service Bus, Redis, Microsoft Sentinel, active-active writes and a Sweden Central AI deployment are not included in Release 1.

## 4. Scope boundaries

### Included in the Azure estimate

- Production Azure resources in both regions.
- Normal Front Door requests, transfer and WAF use.
- SQL compute, storage, backup and geo-replication allowance.
- Critical Blob replication, versioning, soft delete and upload scanning.
- Private Link, Private DNS, Key Vault and routine bandwidth.
- Controlled monitoring ingestion, retention, alerting and selected Defender plans.
- Pay-as-you-go Azure OpenAI use capped by the application.
- Tenants' minor Azure control-plane consumption and public DNS allowance.
- Normal monthly variability through contingency.

### Excluded from the Azure run-rate

- VAT, taxes and changes in foreign-exchange treatment.
- Employee, consultant, support and on-call labour.
- Existing on-premises cost during migration.
- Microsoft Entra or Microsoft 365 licences already purchased by the company.
- GitHub paid-plan licences if not already available.
- Payment, delivery, email, SMS, mapping and other provider fees.
- End-user devices, office connectivity and customer-support systems.
- Premium Microsoft support, incident consultants or cyber-insurance.
- Unusually large media delivery, attack traffic or emergency scaling.

These exclusions belong in the business budget. They are not zero-cost elements of the transformation.

## 5. Workload and sizing assumptions

| Area | Release 1 assumption |
|---|---|
| Employees | Approximately 35 |
| Registered customers | Approximately 40,000 |
| Active vendors | Approximately 150 |
| Daily orders | Approximately 600 |
| Primary App Service | P1v3, minimum 2 and maximum 4 workers |
| Standby App Service | P1v3, 2 standing standby workers; no scale-up delay for DR |
| Database | General Purpose, provisioned 2 vCores in each region |
| Availability | Active primary with warm regional standby |
| Recovery objectives | RPO no more than 15 minutes; RTO no more than 60 minutes |
| Monitoring | Sampling and retention controlled by data classification |
| AI | Pay-as-you-go inference; no provisioned throughput |
| Pricing basis | 730-hour planning month, rounded estimates |

Sizing is a starting hypothesis. Load, security, migration and DR tests must prove it before cutover.

## 6. Release 1 monthly Azure estimate

| Cost area | Costed configuration | Monthly estimate | Confidence |
|---|---|---:|---|
| Primary application hosting | Two P1v3 workers in West Europe | DKK 2,900 | High |
| Warm-standby hosting | Two P1v3 workers in Sweden Central (raised from one; see ADR-004 addendum) | DKK 2,900 | High |
| Azure SQL primary | GP provisioned 2-vCore database, zone-redundant configuration, storage and backup allowance (zone redundancy added; see ADR-005 addendum) | DKK 2,600 | Medium |
| Azure SQL geo-secondary | Equal-size secondary, storage and replication allowance | DKK 2,400 | Medium |
| Front Door Standard and WAF | Profile, four routes/origin groups, WAF policy, requests and moderate transfer | DKK 650 | Medium |
| Storage and data protection | Two accounts, capacity, operations, versioning, soft delete, replication and backup | DKK 350 | Medium |
| Monitoring and alerting | Application Insights, Log Analytics, diagnostics, alerts and retention | DKK 700 | Low–medium |
| Private connectivity | Seven private endpoints and routine processing | DKK 350 | High–medium |
| Key Vault and DNS | Two vaults, operations, certificates and DNS zones | DKK 50 | High–medium |
| Defender and malware scanning | Selected protection plus bounded Blob scan volume | DKK 350 | Low–medium |
| AI Operations Assistant | Pay-as-you-go inference with application-enforced cap | DKK 300 | Low–medium |
| Bandwidth and regional transfer | Normal internet responses and replication traffic | DKK 350 | Low–medium |
| Minor platform services | Public DNS, delivery and control-plane allowance | DKK 50 | Medium |
| **Estimated Azure operating subtotal** |  | **DKK 13,950** |  |
| Planning contingency | Approximately 7.5% for normal consumption and price variance | DKK 1,050 |  |
| **Normal-operation planning baseline** |  | **DKK 15,000** |  |

The DKK 1,500 difference between the planning baseline and the DKK 16,500 authorization is headroom, not a target to spend.

**V6 change note:** the Sweden Central standby plan moved from one warm worker to a standing minimum of two, and the West Europe SQL database moved to a zone-redundant configuration. Together these add DKK 1,650/month (DKK 1,450 for the second standby worker, DKK 200 for zone redundancy) over the V5 baseline. This closes the two largest disclosed resilience gaps in the design — a single-instance DR standby and a single-zone primary database — at a cost that keeps normal-month spend within the newly authorized DKK 16,500 envelope. See `docs/architecture/10-architecture-decisions.md` ADR-004 and ADR-005 for the full rationale.

## 7. Estimate confidence and sensitivity

| Cost behaviour | Main examples | Treatment |
|---|---|---|
| Mostly fixed | P1v3 workers and provisioned SQL compute | High-confidence quantity; re-price by region |
| Usage sensitive | Front Door, bandwidth, Storage operations and private-link processing | Validate with traffic and media assumptions |
| Telemetry sensitive | Log Analytics, Application Insights and security logs | Control ingestion, sampling and retention by table |
| Workload sensitive | AI tokens and malware-scanned upload volume | Enforce application quotas and upload limits |
| Event sensitive | DR operation, penetration tests and campaign scaling | Approve separately and time-limit extra capacity |

The largest financial risks are SQL sizing, telemetry volume, additional App Service workers, outbound media transfer and deferred security services. A 20% change in one small consumption line does not threaten the budget; adding permanent compute or a larger SQL tier does.

## 8. Normal, peak and DR scenarios

| Scenario | Expected monthly cost | Approval position |
|---|---:|---|
| Lower-usage normal month | DKK 12,000–13,000 | Within baseline |
| Planned normal month | DKK 15,000 | Baseline |
| Upper normal range | DKK 14,000–15,000 | Within authorization; investigate variance |
| Seasonal campaign month | DKK 15,500–18,000 | Temporary approval required |
| Full-month DR operation | DKK 16,300–18,800 | Incident funding and reforecast required |

### Seasonal peak assumptions

- West Europe averages three rather than two workers for part or all of the month.
- SQL is temporarily scaled after load evidence.
- Requests, egress, Storage operations, logs and AI use increase.
- Every pre-scale action has an expiry date and owner.

### Regional failover exposure

| Elevated Sweden Central operation | Extra cost above a normal month |
|---|---:|
| Up to 24 hours | DKK 100–300 |
| Seven days | DKK 700–1,800 |
| Full month | DKK 3,000–5,500 |

This assumes the primary resources are retained for recovery and failback. Normal headroom must not be treated as the incident reserve.

## 9. One-time implementation and migration estimate

This section estimates incremental Azure consumption during the 16-week delivery. Labour remains excluded because staffing mix, internal salary allocation and supplier day rates have not been approved.

| One-time Azure item | Planning range |
|---|---:|
| Controlled development and test environments during delivery | DKK 6,000–12,000 |
| Parallel on-premises/Azure migration overlap for one to two months | DKK 3,000–12,000 |
| Load, penetration and DR test events | DKK 3,000–9,000 |
| Temporary data copies, transfer, diagnostics and contingency | DKK 2,000–5,000 |
| **One-time Azure delivery allowance** | **DKK 14,000–38,000** |

Non-production should use smaller capacity, schedules and expiry tags. Production-sized dual-region resources should run in non-production only during a defined rehearsal.

## 10. Year 1 forecast

| Period | Cost assumption | Estimated Azure cost |
|---|---|---:|
| Implementation months | Temporary environments and migration activity | DKK 14,000–38,000 total incremental |
| First 90 production days | Pay-as-you-go baseline while measuring real usage | DKK 39,900–45,000 |
| Remaining nine production months | Normal baseline with occasional controlled variance | DKK 119,700–135,000 |
| **First full production-year run-rate** | Excludes one-time delivery spend | **DKK 159,600–180,000** |

After 90 days, Nordic Shopping should replace assumptions with Cost Management exports and measured unit costs per order, active customer, vendor and API request.

## 11. Future business and architecture assumptions

| Metric | Release 1 | Three-year target | Five-year assumption |
|---|---:|---:|---:|
| Registered customers | 40,000 | 250,000 | 400,000+ |
| Active vendors | 150 | 800 | 1,500+ |
| Daily orders | 600 | 5,000 | 8,000–12,000 |
| Markets | Denmark | Denmark, Sweden and Norway | Wider Nordic market |
| Release pattern | Monthly | Weekly/on demand | Multiple releases per week |

Growth does not create a smooth cost curve. The bill rises in steps when an additional plan, database tier or security service is approved.

## 12. Future operating-cost estimation

| Stage | Expected architecture position | Monthly estimate | Annualized estimate |
|---|---|---:|---:|
| Release 1 | Shared regional plans, 2-vCore SQL pair, warm standby | DKK 15,000 | DKK 180,000 |
| Year 1 upper envelope | Normal variance within authorization | Up to DKK 16,500 | Up to DKK 198,000 |
| Year 2 growth | More compute/SQL capacity and higher telemetry/traffic | DKK 16,000–21,000 | DKK 192,000–252,000 |
| Three-year target | Dedicated API capacity, larger data tier and integration/security growth | DKK 22,000–28,000 | DKK 264,000–336,000 |
| Five-year Nordic expansion | More independent plans, larger data platform and mature security operations | DKK 38,000–55,000 | DKK 456,000–660,000 |

These ranges are conditional forecasts, not pre-approved budgets. Each stage requires a new calculator export, architecture review and business approval.

## 13. Three-year estimate by cost area

| Cost area | Expected monthly range |
|---|---:|
| Customer application plans and DR capacity | DKK 3,000–4,000 |
| Dedicated API plans and DR capacity | DKK 4,000–5,500 |
| Vendor and Admin plans and DR capacity | DKK 2,000–3,000 |
| SQL primary, secondary, storage and backup | DKK 6,000–8,000 |
| Front Door, WAF and bandwidth | DKK 1,200–1,800 |
| Monitoring and security | DKK 2,000–2,800 |
| Private networking, integrations and messaging | DKK 1,000–1,800 |
| Storage, AI and miscellaneous consumption | DKK 1,200–1,800 |
| **Three-year total** | **DKK 22,000–28,000** |

## 14. Five-year estimate by cost area

| Cost area | Expected monthly range |
|---|---:|
| Regional application compute and standby capacity | DKK 13,000–18,000 |
| Database, reporting, backup and recovery | DKK 11,000–16,000 |
| Edge, API management, cache and messaging | DKK 4,000–7,000 |
| Monitoring, Sentinel and security services | DKK 4,000–7,000 |
| Storage, bandwidth, AI and contingency | DKK 6,000–7,000 |
| **Five-year total** | **DKK 38,000–55,000** |

## 15. Deferred capability cost effects

The following values are order-of-magnitude increments for decision planning. They must be re-priced when a trigger occurs.

| Deferred change | Approximate monthly increase | Trigger |
|---|---:|---|
| Front Door Standard to Premium | DKK 1,800–3,000 | Managed WAF/bot rules, private origins or compliance need |
| Separate API plans in both regions | DKK 3,000–5,000 | Shared-plan contention or independent scaling requirement |
| API Management | DKK 1,500–6,000 | API governance, partner onboarding, quotas or lifecycle complexity |
| Service Bus | DKK 200–1,000 | Outbox throughput, fan-out or independent consumer requirements |
| Managed Redis-compatible cache | DKK 500–2,000 | Proven repeat-read latency or SQL pressure |
| Microsoft Sentinel | DKK 1,000–5,000+ | Formal SOC, SIEM correlation, automation or compliance |
| Sweden Central AI deployment | DKK 100–700 | AI becomes operationally essential during DR |
| Active-active operating model | DKK 5,000–15,000+ | Continuous multi-region demand and approved data redesign |

Adding every deferred service is not the goal. Each capability must solve a measured problem and receive a new ADR and budget approval.

## 16. Unit economics and allocation

At the Release 1 assumptions:

| Unit view | Planning value |
|---|---:|
| Azure cost per registered customer per month | Approximately DKK 0.38 |
| Azure cost per daily-order equivalent per month | Approximately DKK 25.00 |
| Azure cost per order at 600 orders/day and 30 days | Approximately DKK 0.83 |

These are platform-cost indicators, not profit calculations. They exclude payment fees, labour, refunds, delivery and customer acquisition.

Because the App Services share regional plans, use this initial allocation:

| Cost owner | Allocation |
|---|---:|
| Nordic API | 40% |
| Customer Web | 30% |
| Vendor Portal | 15% |
| Admin Portal | 10% |
| Shared platform | 5% |

Replace these percentages after three months using request volume, compute contribution, telemetry, storage and business ownership.

## 17. Cost controls and budget alerts

| Threshold against DKK 16,500 | Amount | Required action |
|---|---:|---|
| 50% actual | DKK 8,250 | Review month-to-date actual and forecast |
| 70% actual | DKK 11,550 | Investigate compute, SQL, logs and bandwidth |
| 85% actual | DKK 14,025 | Record corrective action or approved peak |
| 95% actual | DKK 15,675 | Escalate to finance and sponsor |
| 100% actual | DKK 16,500 | Require approval for nonessential paid changes |
| 90% forecast | DKK 14,850 | Early warning — investigate trend before it becomes an actual breach |
| 110% forecast | DKK 18,150 | Formal capacity and budget review |

Budget alerts are advisory and must not stop production automatically.

Required controls:

- Tag resources with environment, workload, owner, cost centre, criticality and expiry date.
- Review forecast weekly during migration and the first production month, monthly afterward and quarterly for architecture reforecasting.
- Time-limit campaign capacity and temporary environments.
- Tune SQL and application behaviour before buying a larger tier.
- Apply table-level telemetry retention and sampling without discarding audit evidence.
- Enforce AI and upload limits in the application; an Azure budget alert is not a hard usage cap.
- Consider commitments only after at least three months of stable production measurement.
- Never remove WAF, private access, the SQL secondary, recovery replication or essential monitoring solely to meet an old budget.

## 18. Reforecast and approval triggers

| Trigger | Required decision |
|---|---|
| Forecast exceeds 90% of DKK 16,500 | Investigate variance and prepare optimization or budget change |
| Shared-plan CPU exceeds 70% for sustained periods | Scale temporarily, diagnose and review plan separation |
| API affects other applications | Price dedicated API plans in both regions |
| SQL breaches performance SLO after tuning | Re-price a larger tier and its geo-secondary |
| Logs exceed 10% of the Azure invoice | Review ingestion, duplication, sampling and retention |
| AI or malware-scanning allowance is exceeded | Enforce cap; approve higher consumption only with evidence |
| DR test misses RTO because of capacity | Increase standby capacity and revise baseline |
| New country, regulation or security obligation | Re-price compliance, identity, logging and data-residency controls |
| Any deferred service becomes required | Approve a new ADR and cost baseline before deployment |

## 19. Financial risks

| Risk | Potential impact | Control |
|---|---|---|
| Regional list price or exchange-rate change | Forecast drift | Refresh calculator quarterly and before commitments |
| SQL incorrectly sized | Large fixed over- or under-spend | Benchmark production-like transactions and reports |
| Uncontrolled logs | Rapid variable-cost growth | Table-level budgets, retention and monthly review |
| Shared plans split too early | Avoidable fixed cost | Require measured isolation trigger |
| Shared plans split too late | Incident and emergency scale cost | Capacity alerts and load tests |
| Standby capacity too small | RTO failure | Quarterly DR test and evidence |
| Media egress rises | Campaign bill shock | Image optimization, caching and traffic forecast |
| AI or upload scanning is unbounded | Consumption and governance risk | Quotas, size limits, redaction and audit |
| Commitments bought too early | Unused prepaid capacity | Wait for stable production measurements |
| Labour and providers omitted from business case | Total-cost understatement | Maintain a separate total-cost-of-ownership budget |

## 20. Approval recommendation

Nordic Shopping should:

1. Approve **DKK 15,000/month** as the Release 1 Azure planning baseline.
2. Authorize **DKK 16,500/month** for normal operation, excluding VAT, labour and third-party transaction fees.
3. Reserve **DKK 14,000–38,000** for incremental Azure delivery, rehearsal and migration consumption.
4. Maintain separate approval for seasonal peaks, prolonged DR operation and major security incidents.
5. Rebaseline after 90 days of production evidence and quarterly afterward.
6. Treat DKK 22,000–28,000/month at three years and DKK 38,000–55,000/month at five years as planning ranges, not approved spending.
7. Require an ADR and refreshed estimate before adding any deferred architecture capability.

## 21. Official pricing sources

- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Azure App Service for Linux pricing](https://azure.microsoft.com/pricing/details/app-service/linux/)
- [Azure SQL Database pricing](https://azure.microsoft.com/pricing/details/azure-sql-database/single/)
- [Azure Front Door pricing](https://azure.microsoft.com/pricing/details/frontdoor/)
- [Azure Web Application Firewall pricing](https://azure.microsoft.com/pricing/details/web-application-firewall/)
- [Azure Blob Storage pricing](https://azure.microsoft.com/pricing/details/storage/blobs/)
- [Azure Monitor pricing](https://azure.microsoft.com/pricing/details/monitor/)
- [Azure Private Link pricing](https://azure.microsoft.com/pricing/details/private-link/)
- [Azure Key Vault pricing](https://azure.microsoft.com/pricing/details/key-vault/)
- [Microsoft Defender for Cloud pricing](https://azure.microsoft.com/pricing/details/defender-for-cloud/)
- [Azure bandwidth pricing](https://azure.microsoft.com/pricing/details/bandwidth/)
- [Azure OpenAI pricing](https://azure.microsoft.com/pricing/details/azure-openai/)
- [Microsoft Cost Management](https://azure.microsoft.com/products/cost-management/)

Microsoft prices App Service mainly by plan size and running instance count. Front Door includes a tier fee plus usage meters, with WAF treatment depending on tier. SQL cost depends on compute, storage, backup and redundancy. Defender for Storage and malware scanning depend on protected accounts and scan volume. Azure OpenAI pay-as-you-go cost depends on the chosen model and token usage. These service-specific variables are why the DKK values must be validated in the calculator and then replaced with actual invoices after launch.

## 22. Final financial statement

This cost estimation prices the same architecture that Nordic Shopping has approved and diagrammed. It does not silently replace Front Door Standard, reduce the warm standby, remove the SQL geo-secondary or weaken private access and monitoring.

The financially approved Release 1 position is therefore:

> **Plan for DKK 15,000 per normal month, authorize DKK 16,500, hold a separate migration and incident reserve, and expand the budget only when measured growth or risk triggers an approved architecture change.**
