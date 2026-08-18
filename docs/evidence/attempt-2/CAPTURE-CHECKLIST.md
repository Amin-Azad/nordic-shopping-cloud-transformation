# Screenshot capture checklist

Add only the screenshots below. A small evidence set is easier to verify than a
long gallery.

Before saving an image, hide or crop subscription IDs, tenant IDs, client IDs,
object IDs, email addresses, billing details, tokens and secret values. Keep
workflow names, step names, conclusions, run IDs, resource types and quota
values visible.

| File to add | Capture | Keep visible |
|---|---|---|
| `01-ci-validation.png` | GitHub run 32127953187 job summary | Run ID, successful conclusion, formatting, lint, build and regression-test steps |
| `02-attempt-2-gates.png` | GitHub run 32123367196 job summary | Successful steps through final What-If and the failed deployment step |
| `03-app-service-quota-error.png` | Attempt 2 log or evidence artifact | `SubscriptionIsOverQuotaForSku`, region and SKU; redact account identifiers |
| `04-sql-entra-error.png` | Attempt 2 log or evidence artifact | `InvalidParameterValue`, administrator `Login` context; redact identity values |
| `05-partial-resources.png` | A historical Portal or terminal capture, only if one already exists | Resource types created during the attempt; do not recreate resources for this image |
| `06-cleanup-success.png` | GitHub run 32124949474 job summary | Run ID, successful conclusion and guarded-cleanup steps |
| `07-zero-resource-verification.png` | Existing terminal output from the independent post-cleanup checks | Empty results for resource groups, resources, policies, budgets, Key Vaults and tagged resources |
| `08-region-qualification.png` | GitHub run 32129650123 log summary | Tested regions, SQL/SKU results and `Total VMs = 0` |
| `09-correction-pr.png` | PR #8 overview | Title, merged state and successful infrastructure-validation check |

## Capture notes

- Use PNG.
- Crop browser tabs, bookmarks, desktop notifications and unrelated terminal
  history.
- Use the normal GitHub light or dark theme consistently.
- Do not add arrows, large labels or decorative frames.
- Add a one-sentence caption when placing each image in documentation.
- If screenshots 3, 4, 5 or 7 no longer exist, mark them unavailable. Do not
  recreate evidence or deploy again for a screenshot.
- The workflow links remain the authoritative record; screenshots are only a
  quick visual summary.

## Suggested order on a portfolio page

1. Architecture overview already stored in `architecture/diagrams/exports/`.
2. CI validation.
3. Attempt 2 gates.
4. App Service and SQL errors.
5. Cleanup success and zero-resource verification.
6. Correction PR.
7. Region qualification.
