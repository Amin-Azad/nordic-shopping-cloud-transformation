# Security

This document explains the security risks, implemented controls and remaining limitations of the Nordic Shopping Azure platform.

The project represents a fictional marketplace containing customer details, vendor information, orders, product data and payment references. Full payment-card data is expected to remain with an external payment provider.

The full two-region architecture is a production-oriented design. The smaller Sweden Central profile was deployed and verified as portfolio evidence. Controls are described as implemented only where deployment or runtime evidence exists.

## Security objectives

The platform is designed around the following objectives:

* prevent one vendor from accessing another vendor's data;
* keep SQL, Storage and Key Vault away from direct public access;
* avoid long-lived deployment credentials;
* avoid secrets in source control and application configuration;
* protect infrastructure changes with validation and approval gates;
* collect enough operational evidence to investigate failures;
* preserve the same identity and network controls during recovery;
* document limitations without presenting an untested design as production-ready.

## Main risks

| Risk                                 | Why it matters                                                   | Priority |
| ------------------------------------ | ---------------------------------------------------------------- | -------- |
| Stolen customer or employee account  | Could expose personal or business data                           | High     |
| Cross-vendor data access             | Could expose confidential marketplace information                | Critical |
| Weak API authorization               | An authenticated user could perform an unauthorized action       | Critical |
| Public access to data services       | SQL, Storage or Key Vault could be attacked directly             | High     |
| Secrets stored in source control     | Credentials could be copied and reused                           | High     |
| Excessive Azure permissions          | A compromised identity could change the environment              | High     |
| Direct access to application origins | Traffic could bypass the intended entry controls                 | High     |
| Unsafe file uploads                  | Malicious files could reach users or applications                | High     |
| Duplicate order or payment requests  | Retries could create inconsistent transactions                   | High     |
| Sensitive data in logs               | Tokens, secrets or personal information could be exposed         | High     |
| Incomplete monitoring                | Incidents could remain undetected or be difficult to investigate | Medium   |
| Deployment compromise                | Unreviewed infrastructure changes could reach Azure              | High     |
| Failed regional recovery             | An outage could cause extended downtime or inconsistent data     | High     |
| Unexpected cloud spending            | Abuse or configuration errors could increase cost                | Medium   |

## Identity and access

GitHub Actions authenticates to Azure through OpenID Connect federation. The deployment workflows do not require a stored Azure client secret.

A dedicated user-assigned managed identity is trusted only for the repository's protected `dev` environment. GitHub environment approval provides an additional control before deployment or cleanup begins.

Azure workloads use managed identity where the selected services support it. During the successful minimal-profile deployment, the application used its managed identity to read Key Vault through Azure RBAC. The readiness probe confirmed that the identity, role assignment, private DNS and private endpoint path worked together.

The full design assigns Azure permissions through Microsoft Entra groups instead of directly to individual users. Separate roles are intended for platform administration, development, operations, security review, cost review, database administration and auditing.

Administrative access should use MFA, least privilege and regular access reviews. The portfolio deployment identity currently has broad subscription-level permissions because it creates resources, role assignments, policy assignments and budgets. A production implementation should replace this with narrower custom roles and separate deployment identities for different environments.

## Network and data protection

The deployed minimal profile used private networking for its data services.

The verified controls included:

* SQL public network access disabled;
* Key Vault public network access disabled;
* private endpoints for SQL, Key Vault and Blob Storage;
* private DNS integration;
* network security groups;
* virtual-network integration for the application path;
* managed identity and Azure RBAC for Key Vault access.

The readiness response returned `keyVault.ok: true`. This was stronger evidence than resource creation alone because it confirmed that the deployed application could resolve and reach Key Vault privately and authenticate without a stored secret.

Private networking reduces direct exposure, but it does not provide application authorization. The API must still decide whether an authenticated user is allowed to access a particular order, product or vendor record.

Production data should not be copied into development unless it has been masked. Logs must not contain passwords, access tokens, full payment information, connection strings or unnecessary personal data.

## Application authorization

Vendor separation is the most important application-level risk.

Azure RBAC cannot determine whether a marketplace vendor owns a particular product or order. For each protected request, the API should verify:

* that the token is valid;
* the user's role;
* the requested operation;
* the user's vendor membership;
* ownership of the requested resource;
* whether the operation is allowed in the current business state.

The application must not trust a vendor ID, user ID or role supplied by the browser without validating it on the server.

Customer, vendor and employee identities should remain logically separated. Production access should include MFA and conditional-access policies where appropriate.

Payment and delivery callbacks should verify signatures and reject expired or replayed requests. Order and payment operations should use idempotency so that a retried request cannot create duplicate transactions.

These application controls are design requirements. The Azure infrastructure deployment does not by itself prove that every authorization path has been implemented or tested.

## Secrets

Secrets should be stored in Key Vault and accessed through managed identity wherever possible.

The repository does not store Azure client secrets. GitHub Actions uses OIDC, and the application readiness test proved managed-identity access to Key Vault.

Any remaining secrets should have:

* a named owner;
* a rotation schedule;
* an expiry policy;
* restricted read access;
* audit logging;
* a tested recovery procedure.

Screenshots and committed evidence are reviewed for personal email addresses, subscription IDs, tenant IDs, object IDs, access tokens and connection strings. Evidence is cropped or redacted before it is added to the repository.

## File uploads

Uploaded files should first enter a quarantine location. The application should validate file type and size and scan the file for malware before moving it into trusted storage.

The Bicep design can create the required Storage resources, identities and network controls. Quarantine, scanning and promotion also require application logic and scanning configuration and were not validated by the minimal portfolio deployment.

## Deployment security

Infrastructure changes are stored in Git and deployed through Bicep and GitHub Actions.

The guarded deployment process includes:

1. Bicep build and repository validation.
2. Regional service and SKU checks.
3. Subscription and identity verification.
4. GitHub OIDC authentication.
5. Azure What-If before deployment.
6. Rejection of unexpected destructive changes.
7. Protected-environment approval.
8. An explicit confirmation phrase for deployment or cleanup.
9. Application publication.
10. A readiness test that fails the workflow if the application is not healthy.
11. Evidence collection and artifact upload.
12. Guarded cleanup with a zero-resource check.

Failed deployment attempts are preserved rather than hidden. Attempt 1 and Attempt 2 document the quota, identity and guardrail problems that were found before the successful minimal deployment.

Dependency, secret and application-security scanning should remain enabled or be introduced where application code is expanded.

## Governance, monitoring and response

The deployed profile included Azure Policy assignments, Azure Monitor, Log Analytics, Application Insights, availability monitoring, action groups, service-health monitoring, resource-health monitoring and a budget.

The captured Azure Policy snapshot reported 36% overall compliance, with 27 of 76 evaluated resources compliant. The assignments operated in `Audit` or `AuditIfNotExists` mode. This is recorded as an observed result, not presented as full compliance.

Audit-mode policy is appropriate for observing the portfolio deployment without blocking it unexpectedly. A production rollout should review each non-compliant result, correct legitimate gaps and move selected policies to enforcement only after testing their effect.

Alerts should cover:

* authentication and authorization failures;
* application errors;
* availability-test failures;
* Key Vault access failures;
* SQL health;
* resource changes;
* deployment failures;
* policy drift;
* unusual cloud spending;
* service-health and resource-health events.

Every important alert needs an owner and a response procedure. Creating an action group is not sufficient unless its notifications are tested.

During an incident, the first priorities are to limit damage, preserve evidence and maintain critical operations. Recovery actions should be recorded and reviewed afterward.

## Recovery security

The full design uses the same identity, network and data-protection principles in both regions.

Disaster recovery must not bypass normal access controls. SQL promotion and traffic failover should remain controlled decisions. After recovery, orders, payments and inventory should be checked for missing or duplicated changes.

The two-region design was compiled and What-If validated but was not deployed because of subscription and service limitations. Live regional failover, failback and data-reconciliation testing therefore remain outside the verified scope.

## Risks and controls

| Risk                          | Implemented control                                                                       | Remaining limitation                                                              |
| ----------------------------- | ----------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| Stored deployment credentials | GitHub OIDC federation with a dedicated managed identity                                  | The deployment identity has broad subscription-level roles                        |
| Public data-service exposure  | SQL and Key Vault public access disabled; private endpoints and private DNS deployed      | Continuous production compliance enforcement was not implemented                  |
| Secret exposure               | Key Vault with managed identity and Azure RBAC                                            | Secret rotation and expiry testing were outside the deployment                    |
| Unsafe infrastructure changes | What-If, destructive-change checks, protected environment and confirmation phrases        | Human approval and correct reviewer decisions are still required                  |
| Configuration drift           | Bicep, CI validation and regression tests                                                 | The full production design was not deployed                                       |
| Cross-vendor access           | Server-side authorization is defined as an application requirement                        | Complete negative authorization testing is outside this infrastructure repository |
| Direct-origin access          | Private data paths and planned Front Door access restrictions                             | The minimal profile did not prove the full Front Door and WAF design              |
| Malicious uploads             | Quarantine and scanning pattern documented                                                | Upload scanning requires additional application and security configuration        |
| Incomplete detection          | Application Insights, Log Analytics, availability tests and Azure Monitor alerts deployed | Alert delivery and incident exercises need continued testing                      |
| Regional failure              | Two-region recovery design and SQL failover architecture exist in Bicep                   | Live failover and failback were not tested                                        |
| Unexpected spending           | Azure budget, cost alerts, guarded cleanup and actual-cost evidence                       | Forecasts do not guarantee future consumption                                     |
| Evidence leakage              | Screenshots and text evidence are reviewed and redacted                                   | Every future evidence update still requires manual review                         |

## Production work still required

Before treating the platform as production-ready, I would require:

* narrower deployment roles or custom Azure roles;
* separate identities and approvals for development and production;
* customer, vendor and employee authentication testing;
* cross-vendor negative authorization tests;
* WAF and rate-limit testing;
* secret rotation and expiry testing;
* malicious-upload testing;
* policy remediation followed by controlled enforcement;
* alert-delivery and incident-response exercises;
* backup, restore, failover and failback testing;
* external-provider retry and duplicate-event testing;
* penetration testing and application-security review;
* confirmed data-retention and privacy requirements.

## Evidence boundary

The repository demonstrates a successful guarded deployment of the minimal profile, private connectivity, managed-identity access to Key Vault, monitoring, audit-mode governance, cost capture and guarded cleanup.

It does not claim that the fictional marketplace application, full two-region design or disaster-recovery process has been operated as a production system.
