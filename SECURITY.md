# Security Policy

This is a personal Azure portfolio project based on a fictional company. It does not operate a real production service or contain real customer data.

## Reporting a problem

Please do not report suspected vulnerabilities through a public GitHub issue.

Use GitHub Private Vulnerability Reporting if it is available for this repository. Otherwise, contact the repository owner privately through the contact information on the GitHub profile.

A useful report should include:

- the affected file, workflow or component;
- steps to reproduce the problem;
- the possible impact;
- relevant evidence with sensitive values removed;
- a suggested correction, if known.

Response times cannot be guaranteed because this is a personal project rather than a continuously supported service.

## Sensitive information

Do not commit or publish:

- passwords, API keys or access tokens;
- Azure or GitHub credentials;
- connection strings;
- private keys or certificates;
- personal subscription, tenant or identity values;
- `.env` files containing secrets;
- personal or customer information;
- unredacted deployment output.

If a secret is exposed, it must be revoked or rotated. Deleting it from the latest commit is not enough.

## Repository security approach

The project uses or plans to use:

- GitHub OIDC instead of stored Azure client secrets;
- managed identities for Azure workloads;
- least-privilege RBAC;
- Key Vault for secrets;
- private access to production data services;
- Bicep validation and Azure What-If;
- reviewed deployment and cleanup workflows;
- centralized logging and alerts.

Application authorization, secure coding, dependency scanning and runtime testing remain necessary when real application code is added.

Only systems and Azure resources owned by the repository owner, or explicitly authorized for testing, may be tested.
