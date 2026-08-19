# Security Assessment

I reviewed the planned Azure architecture to understand its main security risks before implementation. This assessment is based on the fictional Nordic Shopping scenario and would need to be repeated with real applications, identities and data.

The platform will contain customer details, vendor information, orders, product data and payment references. Full payment-card information should remain with the payment provider.

The main risks I identified are:

| Risk | Why it matters | Initial priority |
| --- | --- | --- |
| Stolen customer or employee account | Could expose personal or business data | High |
| One vendor accessing another vendor’s data | Could expose confidential marketplace information | Critical |
| Weak API authorization | A signed-in user may perform an action they should not be allowed to perform | Critical |
| Public access to SQL, Storage or Key Vault | Important data services could be attacked directly | High |
| Secrets stored in code or GitHub | Credentials could be copied and reused | High |
| Direct access to App Service origins | Traffic could bypass Front Door and WAF controls | High |
| Unsafe file uploads | Malicious files could reach users or applications | High |
| Duplicate payment or order requests | Could create financial and customer-service problems | High |
| Uncontrolled administrator access | A compromised account could change the whole environment | High |
| Incomplete logging | Incidents could remain undetected or be difficult to investigate | Medium |
| Failed regional recovery | The business could experience a long outage or lose recent data | High |
| External-provider failure | Payment, delivery or notification processing could become inconsistent | High |
| Sensitive information in logs | Tokens, secrets or personal data could be exposed | High |
| Supply-chain or deployment compromise | Unreviewed code or infrastructure could reach production | High |
| Unexpected cloud spending | Abuse or configuration mistakes could increase the bill | Medium |

The most important application risk is vendor separation. Azure RBAC and private networking cannot decide whether a vendor owns a specific product or order. The API must check the user, role, vendor membership, requested action and ownership of the data.

The main infrastructure risks are public data access, excessive permissions and stored credentials. I plan to reduce these through private endpoints, managed identities, Key Vault, Entra groups and GitHub OIDC.

Front Door Standard with custom WAF rules gives basic protection, but it does not remove the need for secure application code, rate limits and API authorization.

Regional replication also creates risk. During a serious failure, the latest changes may not yet exist in the recovery database. Failover should therefore be a controlled human decision followed by order, inventory and payment reconciliation.

Before production, I would expect testing of:

- customer, vendor and employee access;
- cross-vendor access attempts;
- direct-origin and public-data-endpoint access;
- secrets and privileged roles;
- WAF and rate-limit behaviour;
- malicious uploads;
- logging and alert delivery;
- backup, restore, failover and failback;
- external-provider retries and duplicate events.

This assessment identifies design risks. It does not claim that the application controls have been implemented or tested.
