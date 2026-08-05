# Contributing Guidelines

Thank you for your interest in the Nordic Shopping Cloud Transformation project.

This repository is primarily a personal cloud engineering portfolio project. Suggestions, technical feedback, bug reports, and focused contributions are welcome.

## Code of Conduct

Contributors should communicate respectfully, provide constructive feedback, and keep discussions focused on improving the project.

## Before Contributing

Before starting work:

1. Review the existing documentation and open issues.
2. Confirm that the proposed change supports the project scope.
3. Open an issue first for significant architecture or design changes.
4. Do not include confidential, personal, or production data.

## Development Workflow

1. Fork or clone the repository.
2. Create a branch from the latest `main`.
3. Make one focused change.
4. Validate the affected files locally.
5. Commit the change using a clear commit message.
6. Push the branch.
7. Open a pull request against `main`.
8. Merge only after the required checks pass.

Update your local `main` branch before creating a new branch:

```bash
git switch main
git pull --ff-only origin main
```

Create and switch to a working branch:

```bash
git switch -c feature/networking-module
```

## Branch Naming

Use lowercase, descriptive branch names with hyphens between words.

Recommended prefixes:

- `feature/` for new functionality
- `fix/` for bug fixes and corrections
- `docs/` for documentation changes
- `refactor/` for structural improvements
- `test/` for test-related changes
- `chore/` for maintenance work

Examples:

```text
feature/networking-module
feature/monitoring-alerts
fix/private-dns-configuration
docs/update-migration-plan
refactor/app-service-module
test/bicep-validation
chore/update-vscode-settings
```

## Commit Messages

Use clear, concise commit messages following this format:

```text
<type>: <description>
```

Recommended types:

- `feat` for new functionality
- `fix` for a correction
- `docs` for documentation
- `refactor` for restructuring without changing behavior
- `test` for tests
- `chore` for maintenance
- `ci` for CI/CD workflow changes
- `security` for security improvements

Examples:

```text
feat: add virtual network module
fix: correct App Service private DNS configuration
docs: update disaster recovery procedure
test: add Bicep validation checks
ci: add infrastructure validation workflow
chore: update VS Code recommendations
```

Use the imperative form, keep the first line concise, and keep each commit focused on one logical change.

## Development Standards

All contributions should:

- Follow the existing repository structure.
- Use two-space indentation unless a file format requires otherwise.
- Use UTF-8 encoding and LF line endings.
- End files with a newline.
- Remove trailing whitespace.
- Avoid committing generated, temporary, or local configuration files.
- Keep changes limited to the purpose of the branch.
- Update related documentation when behavior or architecture changes.

The repository includes `.editorconfig`, `.gitattributes`, and shared VS Code settings to support consistent formatting.

## Validation

Run the checks relevant to the change before opening a pull request.

### General validation

Check for whitespace and formatting problems:

```bash
git diff --check
```

Review the changed files:

```bash
git status --short
git diff
```

### Markdown validation

If Markdownlint is available:

```bash
npx markdownlint-cli2 "**/*.md"
```

Documentation should also be reviewed in the VS Code Markdown preview.

### Bicep formatting and compilation

Format each modified Bicep file:

```bash
az bicep format --file <bicep-file>
```

Compile the entry-point template:

```bash
az bicep build --file <template-file>
```

Example:

```bash
az bicep format --file infra/bicep/main.bicep
az bicep build --file infra/bicep/main.bicep
```

### Azure preflight validation

Validate the deployment without creating resources:

```bash
az deployment sub validate \
  --location <deployment-region> \
  --template-file <template-file> \
  --parameters <parameter-file>
```

Preview proposed Azure changes before deployment:

```bash
az deployment sub what-if \
  --location <deployment-region> \
  --template-file <template-file> \
  --parameters <parameter-file>
```

Use the corresponding resource-group deployment commands when the template targets resource-group scope.

Do not deploy from an unreviewed branch.

### Application validation

From the application directory, install the locked dependencies and run the available checks:

```bash
npm ci
npm test
```

When configured, also run:

```bash
npm run lint
npm run build
```

Additional validation commands will be added as the application and automated workflows are implemented.

## Infrastructure Guidelines

Infrastructure contributions should:

- Use reusable and appropriately scoped Bicep modules.
- Follow the project naming and tagging conventions.
- Keep environment-specific values in parameter files.
- Use symbolic resource references instead of manually constructed resource IDs where practical.
- Use managed identities instead of stored credentials.
- Store secrets and sensitive configuration in Azure Key Vault.
- Use least-privilege Azure RBAC assignments.
- Prefer private connectivity for supported data services.
- Disable public access when the design does not require it.
- Configure diagnostic settings for important resources.
- Consider availability, disaster recovery, security, operations, and cost.
- Use approved Azure regions defined by the project architecture.
- Avoid hard-coded subscription IDs, tenant IDs, object IDs, credentials, secrets, or personal values.

Changes that can increase Azure cost should explain:

- Which resources create the additional cost.
- Whether the resources are temporary or persistent.
- How the change fits the project budget.
- How test resources will be removed after validation.

## Environment and Parameter Files

Safe example parameter files may be committed when they contain only non-sensitive placeholder values.

Do not commit:

- Local parameter files containing personal or subscription-specific values
- Deployment outputs containing sensitive information
- `.env` files
- Access tokens or credentials
- Connection strings
- Certificates or private keys

Use placeholder values in documentation and examples.

## Documentation Guidelines

Documentation contributions should:

- Use clear and direct language.
- Reflect the implemented architecture.
- Distinguish planned features from completed and tested features.
- Use relative links for files within the repository.
- Use descriptive headings and meaningful link text.
- Explain important architectural decisions and trade-offs.
- Avoid unsupported claims or unverified deployment results.
- Update related diagrams when architectural relationships change.

Source diagrams belong in:

```text
architecture/diagrams/source/
```

Exported diagrams belong in:

```text
architecture/diagrams/exports/
```

Do not remove editable diagram sources when adding exported versions.

## Testing Expectations

Tests should be included or updated when practical.

At minimum:

- Bicep templates must compile successfully.
- Deployment changes must pass the appropriate Azure validation.
- Significant deployment changes must be reviewed with Azure what-if.
- Application changes must pass the relevant test and lint commands.
- Documentation links and commands must be checked.
- No secret or sensitive value may appear in the diff.

If a check cannot be performed, explain why in the pull request.

## Pull Requests

A pull request should:

- Use a clear and descriptive title.
- Explain what changed and why.
- Reference the related issue when applicable.
- Identify affected architecture components or documentation.
- Describe the validation performed.
- Include relevant screenshots, diagrams, or deployment evidence when useful.
- Explain cost or security implications when applicable.
- Contain no credentials, secrets, tokens, or sensitive output.
- Avoid unrelated formatting or structural changes.
- Be small enough to review effectively.

Suggested pull request description:

```markdown
## Summary

Briefly describe the change and its purpose.

## Changes

- List the main changes.

## Validation

- List the commands and checks performed.

## Security and Cost Impact

Describe any security, access, regional, or cost implications.

## Evidence

Add relevant screenshots, what-if summaries, or test results when applicable.
```

## Issues

Use issues to report:

- Bugs
- Documentation errors
- Architecture questions
- Proposed enhancements
- Missing tests or validation
- Operational or security improvements

An issue should include:

- A clear title
- The current behavior or problem
- The expected outcome
- Relevant files or components
- Reproduction steps when applicable
- Supporting evidence with sensitive information removed

## Security

Never commit or publish:

- Passwords
- API keys
- Azure credentials
- GitHub tokens
- Connection strings
- Private certificates or keys
- Sensitive deployment outputs
- Personal or customer information

Do not report suspected security vulnerabilities through a public issue.

Follow the private reporting instructions in [SECURITY.md](SECURITY.md).

## Licensing

By contributing to this repository, you agree that your contribution may be distributed under the terms of the [MIT License](LICENSE).

## Questions

For general questions, open a GitHub issue with enough context to understand the problem. Use the private process described in `SECURITY.md` for security-related matters.
