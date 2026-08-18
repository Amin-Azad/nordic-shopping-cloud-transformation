# Attempt 2 evidence

This directory identifies the minimum visual evidence needed for the portfolio.
The written record is in
[the Attempt 2 report](../../deployment-attempts/deployment-attempt-2-controlled-failure.md).

GitHub already provides the primary evidence:

| Evidence | Result |
|---|---|
| [Guarded deployment run 32123367196](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32123367196) | Failed during resource creation after the preceding gates passed |
| Deployment artifact `dev-deployment-evidence-32123367196` | Uploaded by the deployment workflow |
| [Guarded cleanup run 32124949474](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32124949474) | Passed |
| Cleanup artifact `dev-cleanup-evidence-32124949474` | Uploaded by the cleanup workflow |
| [Correction PR #8](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/pull/8) | Merged |
| [Correction CI run 32127953187](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32127953187) | Passed |
| [Region qualification 32129650123](https://github.com/Amin-Azad/nordic-shopping-cloud-transformation/actions/runs/32129650123) | Stopped because no tested region qualified |

Do not copy complete raw logs into the repository. They are noisy, can expose
account metadata and may expire. Use the run links, the short factual report and
the selected screenshots listed in
[`CAPTURE-CHECKLIST.md`](CAPTURE-CHECKLIST.md).

Screenshot files should be added to:

```text
docs/evidence/attempt-2/screenshots/
```

The directory is intentionally absent until reviewed screenshots are available.
