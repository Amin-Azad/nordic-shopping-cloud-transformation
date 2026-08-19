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
