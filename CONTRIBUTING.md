# Contributing

This is mainly a personal cloud-engineering portfolio project. Focused suggestions, corrections and technical feedback are welcome.

## Workflow

1. Create a branch from the latest `main`.
2. Make one focused change.
3. Run the checks related to that change.
4. Use a clear commit message.
5. Open a pull request against `main`.
6. Merge only after the required checks pass.

Example:

```bash
git switch main
git pull --ff-only origin main
git switch -c docs/update-architecture
```

Use short commit messages such as:

```text
docs: clarify recovery assumptions
fix: correct private DNS configuration
test: add deployment regression check
```

## Basic checks

Before opening a pull request:

```bash
git diff --check
git status --short
```

For infrastructure changes, also run:

```bash
az bicep lint --file infra/bicep/main.bicep
az bicep build --file infra/bicep/main.bicep
bash tests/infrastructure/validate-attempt-2-regressions.sh
bash tests/infrastructure/validate-design-consistency.sh
```

## Project rules

- Do not commit credentials or personal Azure identifiers.
- Keep environment-specific values in parameter files.
- Use managed identity or OIDC where supported.
- Keep changes limited to the purpose of the branch.
- Distinguish planned work from implemented and validated work.
- Update documentation when architecture or behaviour changes.
- Do not present a successful build or What-If as a successful deployment.
- Explain meaningful security or cost effects in the pull request.

Report suspected security problems privately by following [SECURITY.md](SECURITY.md).
