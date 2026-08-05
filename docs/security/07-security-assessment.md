# Nordic Shopping Cloud Transformation — Security Assessment

| Item | Value |
|---|---|
| Company | Nordic Shopping |
| Document | Security Assessment |
| Owner | Amin Azad |
| Version | Final V6 |
| Status | Implementation and go-live baseline |
| Date | 28 July 2026 |
| First issued | 25 July 2026 |
| Primary region | West Europe |
| Disaster-recovery region | Sweden Central |
| Related documents | `docs/architecture/04-target-architecture.md`, `docs/cost/06-cost-estimation.md` |

## 1. Executive summary

Nordic Shopping is moving its customer, vendor, administration and API workloads from a single on-premises environment to a managed Azure platform. The target design materially improves security through centralized identity, protected public ingress, private data access, managed workload identities, repeatable deployment and centralized audit evidence.

The proposed architecture is suitable for implementation provided the mandatory controls and go-live tests in this assessment are completed. Its main residual risks are the limited WAF capability of Front Door Standard, dependence on application-level authorization in a multi-tenant marketplace, shared App Service compute, third-party provider exposure, asynchronous regional replication and the absence of a continuously staffed security operations function.

Security approval is therefore **conditional**. Production cutover must not occur with unresolved critical or high findings, untested recovery access, public data endpoints, shared administrator accounts, stored Azure deployment secrets, or unverified vendor isolation.

## 2. Scope and assumptions

### In scope

- Customer Web, customer mobile client and Nordic API
- Vendor Portal, vendor mobile client and B2B vendor identities
- Admin Portal and workforce identities
- Azure Front Door Standard, WAF policy and origin restrictions
- App Services, staging slots and managed identities
- Azure SQL Database, Blob Storage, Key Vault and Azure OpenAI
- VNets, integration subnets, private endpoints and Private DNS
- GitHub Actions, OIDC federation and Bicep deployments
- Application Insights, Log Analytics, Azure Monitor and Defender for Cloud
- Payment, email, SMS and delivery-provider integrations
- Backup, replication, disaster recovery and security administration
- Personal-data protection, logging, retention and GDPR-related controls

### Assumptions

- West Europe is active and Sweden Central is a warm standby.
- The Nordic API is the only application tier authorized to access transactional data.
- Customer identity uses an Entra External ID external tenant.
- Vendors use approved B2B guest accounts in the workforce tenant.
- Employees use workforce Entra ID with MFA and Conditional Access.
- SQL, Blob Storage, Key Vault and Azure OpenAI have public network access disabled.
- The AI Operations Assistant is employee-only, read-only and unable to change production.
- Payment-card data is handled by a compliant payment provider; Nordic Shopping does not store full card data, CVV or provider secrets in logs.
- The company remains responsible for secure application code, identity configuration, data handling and operational response under Azure's shared-responsibility model.

## 3. Security objectives

The platform must provide:

1. Strong separation between customers, vendors, employees and workloads.
2. Least-privilege access to Azure resources and business data.
3. A single protected public ingress path through Front Door.
4. Private access to sensitive platform services.
5. Encryption in transit and at rest.
6. Traceable and approved production changes.
7. Timely detection, investigation and response.
8. Recoverable services without weakening controls during disaster recovery.
9. Protection of personal, commercial and operational data.
10. Evidence that controls work before go-live and throughout operation.

## 4. Data classification and handling

| Class | Examples | Minimum handling |
|---|---|---|
| Public | Product catalogue, public prices, marketing content | Integrity controls; approved caching and publishing |
| Internal | Runbooks, architecture, non-sensitive operational metrics | Workforce access; no public sharing by default |
| Confidential | Orders, vendor commercial data, support records, employee data | Need-to-know RBAC, private storage, encryption, audit logging |
| Restricted | Password-reset material, identity claims, tokens, secrets, payment references | Never log raw values; Key Vault or identity platform; strict retention and access review |

Personal data must be collected for a defined purpose, minimized, retained only as required and removed or anonymized when the retention period expires. Production data must not be copied into development or test unless it is irreversibly masked and formally approved.

## 5. Identity and access management

### 5.1 Identity boundaries

| Actor | Identity system | Required controls |
|---|---|---|
| Customers | Entra External ID external tenant | Secure sign-up/sign-in, verified recovery, risk monitoring, rate limiting |
| Vendors | Workforce tenant B2B guests | Invitation approval, MFA, terms acceptance, vendor membership and periodic review |
| Employees | Workforce Entra ID | MFA, Conditional Access, device/location/risk controls as licensed, group-based roles |
| Workloads | System-assigned managed identities | No stored service credentials; minimum data-plane roles |
| GitHub Actions | Federated workload identity | Repository, branch and environment-bound trust; short-lived tokens |
| Emergency administrators | Dedicated cloud-only accounts | Two accounts, strong MFA, monitored use, sealed recovery process |

Customer identities must not be created in the workforce directory. Vendor guests must not receive employee roles merely because they exist in the workforce tenant. Joiner, mover and leaver processes must remove vendor and employee access promptly.

### 5.2 Application authorization

The API must validate token signature, issuer, audience, lifetime and required scopes. It must then enforce application roles, vendor membership, tenant/vendor identifier, resource ownership and action-level permission on every protected request.

Vendor isolation is a critical control. Every vendor-owned record must carry an authoritative vendor identifier, and the API must derive allowed vendor context from trusted server-side claims or membership data—not from a client-supplied identifier alone. Object-level authorization tests must attempt cross-vendor reads, updates, exports and order actions.

Administrative actions require dedicated roles. High-impact functions such as refunds, vendor approval, role assignment, data export and DR activation require stronger authorization, audit evidence and, where practical, separation of duties.

### 5.3 Azure administration

- Assign Azure roles to Entra groups, not directly to individuals except documented emergencies.
- Separate Reader, Operator, Deployment and Security responsibilities.
- Use Privileged Identity Management for just-in-time privileged access when licensing permits.
- Review privileged roles monthly and all production access quarterly.
- Deny routine use of subscription Owner and User Access Administrator.
- Disable legacy authentication and shared administrator accounts.
- Record and alert on privilege changes, failed privileged sign-ins and emergency-account use.

## 6. Edge, network and application protection

### 6.1 Public ingress

Azure Front Door is the only public application entry point. HTTPS is mandatory and HTTP redirects to HTTPS. Managed certificates are used for approved domains. API responses, authenticated pages and administration content must not be cached.

The WAF policy begins in detection mode during tuning and moves to prevention before production. Initial custom controls include unsupported-method blocking, request-size limits, endpoint-specific rate limits, emergency IP blocks and tighter protection for authentication and admin paths. Thresholds must come from performance testing and observed normal traffic.

Front Door Standard does not provide the same managed WAF rule-set and private-origin capability as Premium. Compensating controls are secure coding, strict input validation, rate limiting, origin restrictions, dependency scanning and security testing. Upgrade to Premium must be reviewed if attacks increase, managed rules become a requirement, or the business requires Private Link origins.

### 6.2 Origin protection

Each App Service must:

- Allow `AzureFrontDoor.Backend` only when the correct `X-Azure-FDID` header is present.
- Deny unmatched requests to the main site.
- Apply separate default-deny restrictions to the SCM endpoint.
- Accept deployments only through the approved delivery workflow.
- Disable FTP/FTPS and require HTTPS with TLS 1.2 or higher.

Tests must prove that direct `azurewebsites.net` requests, missing or incorrect Front Door IDs and unauthorized SCM access are denied. The Front Door ID check is an origin restriction, not a substitute for user authentication or API authorization.

### 6.3 Private service access

The Nordic API reaches SQL, Blob, Key Vault and Azure OpenAI through VNet integration, Private DNS and service-specific private endpoints. Network reachability and authorization remain separate controls: a private route does not grant data access.

| Region | Private DNS and endpoint design |
|---|---|
| West Europe | SQL, Blob, Key Vault and Azure OpenAI |
| Sweden Central | SQL, Blob and Key Vault only |

No Azure OpenAI endpoint or private DNS dependency is required in Sweden Central in release 1. The API must fail safely or disable AI assistance during regional recovery.

Public network access must remain disabled after private-resolution and identity tests pass. Portals and mobile clients must never access these services directly. Egress to third-party providers is not fully allow-listed in release 1; Azure Firewall or NAT Gateway becomes an upgrade consideration if stable outbound IPs, regulatory inspection or strict destination control is required.

### 6.4 Application security

- Apply server-side validation, output encoding and parameterized SQL access.
- Use secure, `HttpOnly`, `Secure` and appropriate `SameSite` cookie settings where cookies are used.
- Configure CORS with explicit approved origins; never use wildcard origins with credentials.
- Protect state-changing browser actions against CSRF.
- Use idempotency keys for retriable order, payment and fulfilment operations.
- Do not expose internal errors, stack traces, secrets or personal data to clients.
- Set security headers including HSTS, Content-Security-Policy, frame restrictions and content-type protection.
- Define upload size, type, malware-scanning and quarantine controls before enabling user uploads.
- Keep sessions, jobs and locks out of local App Service storage.

## 7. Data, secret and cryptographic protection

### 7.1 Azure SQL

- Disable public network access and use a private endpoint in each region.
- Use Entra administration and managed identity where supported; avoid SQL passwords.
- Grant the API only required database permissions; separate migration permissions from runtime permissions.
- Enable auditing and retain evidence according to the approved policy.
- Use Transparent Data Encryption and encrypted TLS connections.
- Protect sensitive values from query strings, logs and diagnostic output.
- Test point-in-time restore and regional failover independently.

Database migrations must be backward compatible with the prior application version during slot deployment and rollback. Destructive schema changes require backup evidence, explicit approval and a tested recovery method.

### 7.2 Blob Storage

- Disable public access and shared-key authorization where operationally feasible.
- Use managed identity with the narrowest container-level roles practical.
- Enable versioning, soft delete and lifecycle rules according to data class.
- Replicate only approved critical objects to the DR account.
- Do not treat object replication as backup or proof of recoverability.
- Validate upload content and prevent active content from executing in trusted application origins.

### 7.3 Key Vault

Each region has an independent private Key Vault with RBAC, soft delete and purge protection. Secrets are deliberately not replicated automatically. Required DR secrets and certificates must be provisioned through a controlled process and tested before a failover exercise.

Applications use Key Vault references or runtime managed-identity retrieval. Secret values must not appear in Bicep parameter files, GitHub variables, deployment output, logs, tickets or documentation. Rotation ownership and expiry alerts are mandatory for provider credentials and certificates.

### 7.4 Encryption and key ownership

Azure platform-managed encryption is acceptable for release 1 unless legal, contractual or risk review requires customer-managed keys. Any move to customer-managed keys must include key availability, rotation, separation of duties, backup and DR consequences; it must not be adopted only as a label of stronger security.

## 8. External providers and webhook security

Outbound payment, email, SMS and delivery calls must use TLS, short timeouts, bounded retries, circuit breakers and idempotency. Provider credentials are stored in Key Vault and granted only to the API identity that needs them.

Inbound webhooks must enter through the Front Door API route and must:

1. Verify a provider signature or equivalent authentication using the raw request body.
2. Enforce timestamp tolerance and replay protection.
3. Validate event schema, provider account and allowed event type.
4. Deduplicate by provider event identifier.
5. Return a safe response without exposing processing details.
6. Record an auditable correlation ID and processing outcome.
7. Reconcile provider state when delivery is missed, duplicated or out of order.

IP allow-lists may be a supplementary control but must not replace signature validation unless the provider offers no stronger mechanism and the exception is approved.

## 9. Secure software delivery

GitHub Actions authenticates to Azure using OIDC workload federation. No long-lived Azure client secret may be stored in GitHub. Federated credentials must be restricted by organization, repository, branch or protected environment subject, and intended audience.

The delivery process must include:

- Branch protection, peer review and protected production environments.
- Build, unit/integration tests, dependency and secret scanning.
- Bicep lint/validation and `what-if` review.
- Immutable application artifacts promoted to both regions.
- Deployment to staging slots, warm-up and smoke tests.
- Human approval after successful staging evidence.
- Production slot swap and post-deployment health validation.
- Auditable approvals and a documented rollback decision.

Pipeline identities receive deployment scope only. They cannot grant themselves roles, read application secrets unnecessarily, declare a disaster or enable Front Door DR traffic. Slot swap rollback is used only when database and configuration changes remain compatible.

## 10. Monitoring, detection and incident response

Application Insights and platform diagnostics feed the Log Analytics workspace. Logs require synchronized UTC timestamps, correlation identifiers and separate cloud-role names. Sensitive values must be redacted before ingestion.

### Minimum alert coverage

| Area | Required detection |
|---|---|
| Identity | Risky or repeated failed sign-ins, MFA/Conditional Access failures, privilege changes, emergency-account use |
| Edge | WAF blocks/rate limits, traffic anomalies, origin health degradation, direct-origin attempts |
| Application | Elevated 401/403/429/5xx, latency, failed orders, authorization denials, suspicious exports |
| Data | SQL threats/audit events, unusual data access, Storage authorization failures, Key Vault denials/deletions |
| Delivery | Failed production deployment, unexpected infrastructure drift, federated-credential or role changes |
| DR | Replication lag/failure, unhealthy standby, missing DR secrets, failover or Front Door-origin changes |
| Cost/abuse | Unexpected bandwidth, log or AI consumption spikes |

Alerts must have an owner, severity, response instruction and tested Action Group route. Critical alerts require primary and secondary responders. Monthly reviews must remove noisy alerts and close missing coverage without suppressing genuine risk.

The incident process follows: detect, triage, contain, eradicate, recover, communicate and review. Evidence preservation, GDPR breach assessment and notification decisions must be part of the runbook. An AI-generated summary may assist investigation, but it cannot close incidents or execute remediation.

## 11. AI Operations Assistant security

The assistant is restricted to approved employees and read-only operational use. It may summarize alerts, logs, runbooks and health information, but it must not access unrestricted customer payloads, payment details, raw credentials or unnecessary personal data.

Required controls:

- Retrieve only from approved operational sources through the API's controlled identity.
- Redact tokens, secrets, personal data and payment references before model submission.
- Apply role-based access to both prompts and retrieved context.
- Treat logs and external text as untrusted input and defend against prompt injection.
- Clearly label output as advisory and potentially incomplete.
- Audit user, time, approved data sources and assistant response without storing sensitive prompt content unnecessarily.
- Enforce consumption limits and alert on unusual use.
- Prohibit autonomous production changes, account actions, refunds, deployments and DR activation.
- Provide a kill switch that disables the feature without affecting commerce services.

AI failure must not affect checkout, order processing, vendor fulfilment or recovery of the core platform.

## 12. Privacy, GDPR and retention

Before production, Nordic Shopping must document data categories, purposes, lawful bases, data owners, processors, retention periods and data flows, including Azure and external providers. Data-processing agreements and international-transfer considerations require legal/privacy review.

Operational requirements include:

- Data minimization and privacy by default.
- Defined processes for access, correction, deletion and export requests.
- Separate retention rules for orders, finance, support, identity, audit and telemetry data.
- Restricted and audited administrative exports.
- Masked non-production data.
- Deletion behavior that accounts for backups, replicas and legal retention.
- A documented personal-data breach assessment and notification workflow.

Log Analytics starts with 30-day interactive retention, but security, legal and operational evidence requirements must be confirmed before go-live. Longer retention should use the most appropriate lower-cost tier where available and be included in the cost model.

## 13. Disaster-recovery security

Security controls must survive regional failure. Sweden Central must have current applications, required role assignments, private endpoints, Private DNS, monitoring and independently maintained Key Vault material before it can receive traffic.

The authorized sequence is:

1. Incident commander declares the event and freezes changes.
2. Operations verifies replication state and the security owner approves promotion.
3. SQL secondary is promoted using named privileged access.
4. DR DNS resolution, secrets, certificates, providers and monitoring are validated.
5. Sweden Central compute scales to the approved serving capacity.
6. Smoke tests validate authentication, authorization, data access and provider calls.
7. An authorized operator enables the matching Front Door DR origins.
8. Operations monitors, reconciles data and records every decision.

CI/CD cannot activate DR. Emergency access must not bypass MFA, authorization, audit or origin protection. Failback requires a new change approval, replication validation and reconciliation; it is not performed merely because West Europe becomes available again.

Security exercises must demonstrate the RTO of 60 minutes or less and the RPO of 15 minutes or less without disabling required controls.

## 14. Threat and risk register

Likelihood and impact use Low, Medium and High planning ratings. Residual risk assumes all planned controls are implemented and tested.

| ID | Threat | Likelihood | Impact | Key controls | Residual risk | Owner |
|---|---|---:|---:|---|---:|---|
| S01 | Customer account takeover | Medium | High | External ID protections, rate limits, secure recovery, anomaly monitoring | Medium | Product/Identity |
| S02 | Vendor accesses another vendor's data | Medium | High | Server-side tenant checks, ownership authorization, isolation tests, audit | Medium | Application owner |
| S03 | Employee or guest receives excessive privilege | Medium | High | Group RBAC, MFA, access reviews, PIM, separation of duties | Medium | Identity owner |
| S04 | Direct-origin or application-layer attack bypasses edge intent | Medium | High | Front Door service tag and FDID restrictions, WAF, TLS, secure coding | Medium | Platform owner |
| S05 | Injection or broken object authorization compromises data | Medium | High | Parameterized access, validation, authorization tests, code review, testing | Medium | Engineering lead |
| S06 | Secret leaks through code, pipeline or logs | Medium | High | Managed identity, Key Vault, secret scanning, redaction and rotation | Low | Platform owner |
| S07 | Compromised CI/CD deploys malicious change | Low/Medium | High | OIDC, protected environments, review, scoped roles, immutable artifacts | Medium | DevOps owner |
| S08 | Forged or replayed provider webhook changes orders | Medium | High | Signature, timestamp, replay prevention, deduplication, reconciliation | Low/Medium | Integration owner |
| S09 | Third-party provider compromise or outage disrupts commerce | Medium | High | Least privilege, timeouts, circuit breakers, idempotency, reconciliation | Medium | Product owner |
| S10 | Sensitive information enters logs or AI prompts | Medium | High | Data classification, redaction, access controls, sampling and audit | Medium | Security/Data owner |
| S11 | Shared App Service capacity causes cross-workload denial of service | Medium | Medium/High | Autoscale, quotas, alerts, load tests, plan-separation trigger | Medium | Platform owner |
| S12 | Regional failover loses recent data or required secrets | Low/Medium | High | Replication monitoring, independent DR secrets, RPO tests, reconciliation | Medium | DR owner |
| S13 | Misconfiguration exposes a PaaS service publicly | Low/Medium | High | Bicep, Policy, private endpoints, public-access deny and tests | Low/Medium | Platform owner |
| S14 | Insufficient monitoring delays incident response | Medium | High | Central telemetry, critical alerts, on-call routing, exercises | Medium | Operations owner |
| S15 | Malicious input manipulates AI advice | Medium | Medium | Approved sources, prompt-injection defenses, advisory-only design, no actions | Low/Medium | AI owner |
| S16 | Personal data is retained or exported improperly | Medium | High | Retention schedule, export controls, audits, privacy processes | Medium | Data Protection owner |

Risk owners must accept residual risks formally. Critical or high residual risk requires treatment or executive exception before go-live.

## 15. Security implementation priorities

### Priority 1 — before any production data

- Establish identity tenants, groups, roles, MFA, Conditional Access and emergency accounts.
- Deploy private endpoints and verify private DNS in each region.
- Disable public access to SQL, Blob, Key Vault and Azure OpenAI.
- Configure managed identities, minimum RBAC and Key Vault references.
- Establish Front Door routes, WAF tuning and origin restrictions.
- Configure GitHub OIDC with protected production environments.
- Implement API authentication, authorization and vendor isolation.
- Define data classification, provider-secret handling and logging redaction.

### Priority 2 — before production cutover

- Move WAF to prevention after tuning.
- Complete application, API and webhook security testing.
- Enable platform diagnostics, alerts, Defender coverage and incident routing.
- Test backup restore, SQL promotion, Blob recovery and regional access.
- Confirm DR secrets and certificates independently.
- Complete privacy/retention review and provider agreements.
- Close critical/high findings and document accepted medium risks.

### Priority 3 — within 90 days after go-live

- Run privileged-access and vendor-guest reviews.
- Conduct a full incident exercise and regional failover exercise.
- Reassess log coverage, retention, WAF thresholds and Defender findings.
- Review Front Door Premium, PIM/licensing and stronger egress control triggers.
- Perform an independent penetration test after the platform stabilizes.

## 16. Go-live security acceptance criteria

Security approval requires evidence that:

- All production domains use HTTPS and route through Front Door.
- WAF is in prevention mode with tested exceptions and rate limits.
- Direct origin and unauthorized SCM requests are denied.
- SQL, Blob, Key Vault and Azure OpenAI public access is disabled.
- Private DNS resolves the correct private addresses from each consuming API.
- Only approved API identities have required data-plane access.
- Cross-customer, cross-vendor and privilege-escalation tests fail safely.
- Employees and vendors use MFA; privileged roles are reviewed and minimized.
- GitHub uses OIDC and contains no long-lived Azure deployment secret.
- Staging evidence precedes release approval and production slot swap.
- Provider webhook signature, replay and duplicate-event tests pass.
- Logs and AI inputs contain no known secrets or prohibited personal/payment data.
- Critical alerts reach both primary and secondary responders.
- Restore and DR exercises meet the RPO/RTO targets without disabling controls.
- No unresolved critical/high security findings remain.
- Data retention, processor and incident-notification responsibilities are approved.

## 17. Required evidence and review cycle

| Evidence | Frequency/trigger |
|---|---|
| Privileged role and guest access review | Monthly privileged; quarterly full review |
| Vulnerability/dependency report | Every build; monthly trend review |
| WAF and authentication abuse review | Monthly and after an incident |
| Azure Policy/Defender posture report | Monthly |
| Restore test | Quarterly |
| Regional recovery exercise | At least twice yearly and after major DR change |
| Penetration test | Before go-live, after major exposure change, and annually |
| Secret/certificate expiry review | Continuous alerts; monthly owner review |
| Data retention/privacy review | Annually and after new data use/provider |
| Security risk register | Quarterly and after material architecture change |

## 18. Architecture consistency action — resolved

Two cross-document inconsistencies were identified during earlier review cycles and are recorded here for audit history. Both are resolved in the current Final V6 document set and require no further action:

- **Private DNS zone inventory.** An earlier architecture draft stated in one location that all four private DNS zones link to both VNets. The approved network design has no Azure OpenAI private endpoint in Sweden Central, so the DR VNet requires only SQL, Blob and Key Vault private DNS zones. `docs/architecture/04-target-architecture.md` Section 8.3 now states this correctly (four zones linked in West Europe, three in Sweden Central).
- **Superseded cost figures.** An earlier business case retained the obsolete DKK 6,700–7,200 estimate and DKK 10,000 ceiling. `docs/business/01-business-case.md` and `docs/cost/06-cost-estimation.md` now state the current approved position: DKK 15,000 normal planning baseline, DKK 16,500 authorized envelope.

## 19. Final assessment

The target architecture provides a credible security foundation for Nordic Shopping's current scale and planned growth. It uses appropriate managed Azure controls while keeping application authorization, operational approval and recovery ownership explicit.

The design is **approved for implementation with conditions**. Production approval depends on completing the Priority 1 and Priority 2 controls, meeting every go-live acceptance criterion and obtaining formal acceptance of the remaining medium risks. The two historical cross-document inconsistencies noted in Section 18 are already resolved in this document set.
