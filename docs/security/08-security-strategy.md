# Security Strategy

This note describes how I plan to reduce the risks identified in the security assessment.

My basic approach is to use more than one layer of protection. Network isolation is useful, but it does not replace identity or application authorization.

## Identity and access

Customers will use an external customer identity service. Vendors and employees will use separate workforce identities and roles.

Every App Service will use its own managed identity where Azure supports it. GitHub Actions will authenticate through OIDC instead of using a stored Azure client secret.

Azure permissions will be assigned to Entra groups rather than directly to individual users. Separate groups are planned for platform administration, development, operations, security review, cost review, database administration and auditing.

Administrative access should use MFA, least privilege and regular access reviews.

## Application protection

Azure Front Door and WAF will be the public entry point for the applications. App Service access restrictions will reduce the possibility of bypassing Front Door.

The Nordic API will remain responsible for business authorization. For every protected request, it should check:

- whether the token is valid;
- which role the user has;
- which action is being requested;
- whether the user owns the resource;
- which vendor the user belongs to.

The application should not trust a vendor ID, user ID or role sent by the browser without checking it on the server.

Payment and delivery callbacks should verify signatures and reject expired or repeated requests. Orders and payments should use idempotency so that retrying a request does not create a duplicate transaction.

## Data and secrets

Production SQL, Blob Storage and Key Vault will use private endpoints with public network access disabled.

Managed identity will be used instead of credentials where possible. Other secrets will be stored in Key Vault and should have an owner and rotation process.

Logs should not contain passwords, access tokens, full payment information or unnecessary personal data.

Production data should not be copied into development unless it has been properly masked.

## File uploads

Uploaded files should first enter a quarantine location. They should be checked for type, size and malware before being moved to trusted storage.

The Bicep project can prepare the Storage infrastructure, but the quarantine and promotion process also requires application code and scanning configuration.

## Delivery security

Infrastructure changes will be stored in Git and created through Bicep.

The delivery process should include:

- formatting, linting and Bicep build checks;
- review of the proposed change;
- Azure What-If before deployment;
- OIDC authentication;
- environment approval for sensitive changes;
- an explicit confirmation before deployment or cleanup;
- saved evidence when a deployment fails.

Application security scanning, dependency scanning, secret scanning and dynamic testing should be added when application code is available.

## Monitoring and response

Application Insights, Log Analytics and Azure Monitor will collect the main operational and security signals.

Alerts should cover sign-in problems, application failures, WAF activity, resource changes, Key Vault access, SQL health, deployment failures and unusual spending.

Every important alert needs a person responsible for checking it. A technically correct alert has little value if nobody receives or understands it.

For an incident, the first priorities are to limit the damage, preserve evidence and keep important business operations working. Recovery actions should be recorded and reviewed afterwards.

## Recovery security

The recovery region should use the same main identity, network and data-protection approach as the primary region.

Disaster recovery must not bypass normal access controls. Database promotion and Front Door recovery activation should remain human decisions.

After recovery, orders, payments and inventory should be checked for missing or duplicated changes.

Before production, these controls would need configuration review, negative testing and recovery exercises. This strategy describes the intended security approach; it is not evidence that every control is already operating.
