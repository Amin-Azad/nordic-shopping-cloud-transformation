# Security Policy

Security is a core requirement of the Nordic Shopping Cloud Transformation project. This policy explains how to report vulnerabilities and how sensitive information must be handled.

## Supported Versions

This project is under active development. Security updates apply only to the latest version of the `main` branch.

| Version | Supported |
|---|---|
| Latest `main` branch | Yes |
| Older commits or branches | No |

## Reporting a Vulnerability

Do not report suspected security vulnerabilities through public GitHub issues, discussions, pull requests, or social media.

Use GitHub Private Vulnerability Reporting when it is enabled for this repository:

1. Open the repository on GitHub.
2. Select **Security**.
3. Select **Advisories**.
4. Select **Report a vulnerability**.
5. Provide the information requested below.

If private vulnerability reporting is unavailable, contact the repository owner privately through the contact method listed on the GitHub profile.

## Information to Include

A useful vulnerability report should include:

- A clear description of the vulnerability
- The affected file, component, workflow, or Azure resource
- Steps required to reproduce the issue
- The expected and actual behavior
- The possible security impact
- Relevant logs, screenshots, or proof-of-concept details
- A suggested remediation, if available

Remove credentials, access tokens, personal data, subscription identifiers, tenant identifiers, and other sensitive values before submitting evidence.

## Response Process

After receiving a report, the repository owner will aim to:

1. Acknowledge the report.
2. Review and reproduce the issue.
3. Assess its severity and impact.
4. Develop and validate a remediation.
5. Publish a fix or mitigation when appropriate.
6. Credit the reporter if requested and appropriate.

Response times cannot be guaranteed because this is a personal portfolio project rather than a continuously staffed production service.

## Responsible Disclosure

Please allow reasonable time to investigate and remediate a reported issue before publishing technical details.

Do not:

- Access data that does not belong to you
- Disrupt services or deployments
- Perform destructive testing
- Attempt social engineering
- Use denial-of-service techniques
- Retain, disclose, or modify sensitive information
- Test against systems without authorization

## Secrets and Sensitive Information

Never commit or publish:

- Passwords
- API keys
- Azure credentials
- GitHub tokens
- Connection strings
- Private keys or certificates
- `.env` files containing secrets
- Sensitive deployment outputs
- Customer, vendor, or employee information
- Personal subscription or tenant details

Use placeholder values in examples and documentation.

If a secret is accidentally committed:

1. Revoke or rotate it immediately.
2. Remove it from the current repository content.
3. Review logs for unauthorized use.
4. Assess whether Git history must be cleaned.
5. Document the incident without exposing the secret.

Deleting a secret from the latest commit does not make the exposed value safe. Rotation is still required.

## Infrastructure Security Principles

Infrastructure changes should follow these principles:

- Use managed identities instead of stored credentials.
- Apply least-privilege Azure RBAC.
- Store secrets in Azure Key Vault.
- Use private endpoints where required by the architecture.
- Restrict public network access where practical.
- Protect public traffic with Azure Front Door and Web Application Firewall.
- Encrypt data in transit and at rest.
- Enable diagnostic logs for important resources.
- Centralize monitoring and security alerts.
- Review infrastructure changes with Azure what-if before deployment.
- Keep production and non-production access separated.
- Avoid hard-coded tenant IDs, subscription IDs, object IDs, and credentials.

## CI/CD Security

GitHub Actions workflows should:

- Use OpenID Connect workload identity federation for Azure authentication.
- Avoid long-lived Azure client secrets.
- Use least-privilege workflow permissions.
- Pin third-party actions to trusted versions.
- Protect production environments with approval controls.
- Keep sensitive values in GitHub encrypted secrets or environment secrets.
- Prevent secrets from being printed in workflow logs.
- Validate Bicep templates before deployment.
- Run deployments only from approved branches and environments.

## Dependency and Code Security

Project dependencies should be reviewed and updated regularly.

Application and automation changes should:

- Use supported runtime versions.
- Commit dependency lock files.
- Review dependency vulnerability reports.
- Validate untrusted input.
- Avoid exposing internal error details.
- Apply secure defaults.
- Remove unused packages and permissions.

## Scope

This policy applies to:

- Bicep templates and parameter examples
- GitHub Actions workflows
- Infrastructure regression tests
- Scripts and automation
- Architecture documentation
- Operational procedures
- Repository configuration

Nordic Shopping is a fictional company, and this repository is a portfolio case study. Only systems and Azure resources owned or explicitly authorized by the repository owner may be tested.

## Security Updates

Confirmed vulnerabilities may be addressed through:

- A dedicated security fix
- Configuration hardening
- Documentation updates
- Credential rotation
- Dependency updates
- Workflow permission changes
- Infrastructure redeployment

Security-related changes will be validated before they are merged into `main`.
