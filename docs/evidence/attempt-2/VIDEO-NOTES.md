# Video walkthrough notes

Target length: five to seven minutes.

These are prompts, not a script. Speak in your own words and keep the failed
deployment visible long enough for the viewer to verify it.

## 1. Project and architecture — 45 seconds

- State that Nordic Shopping is a fictional e-commerce transformation case.
- Show the architecture overview.
- Identify the primary and disaster-recovery regions.
- Mention App Service, SQL, Storage, Key Vault, private networking and
  monitoring.

## 2. Repository implementation — 60 seconds

- Show `infra/bicep/main.bicep`, the module folders and the dev/prod parameter
  files.
- Show the GitHub workflow directory.
- Explain that the workflow authenticates to Azure through OIDC rather than a
  stored client secret.

## 3. Guarded deployment — 90 seconds

- Open run 32123367196.
- Point to the successful identity, subscription, Provider validation and final
  What-If steps.
- Point to the failed deployment step.
- State the two errors without dramatizing them: App Service regional
  `Total VMs` capacity was zero, and SQL rejected the Entra administrator
  login value.
- Do not say that the complete environment was deployed.

## 4. Cleanup — 60 seconds

- Open run 32124949474.
- Show the successful guarded cleanup.
- Show the independent empty-result terminal capture if available.
- Explain that cleanup was a separate manually confirmed workflow.

## 5. Correction — 75 seconds

- Open PR #8 and CI run 32127953187.
- Show the separate SKU and `Total VMs` checks.
- Show the SQL administrator correction and the regression-test file.
- Open region qualification run 32129650123 and explain why it stopped.

## 6. Close — 30 seconds

Use your own version of these facts:

- production was not deployed;
- no dev resources remain;
- the subscription cannot currently supply App Service workers in the tested
  regions;
- another deployment was deliberately not attempted; and
- the repository demonstrates Bicep, OIDC, CI/CD controls, Azure validation,
  incident diagnosis, regression tests and cleanup.

## Recording checks

- Record at 1080p.
- Increase terminal and browser text until it is readable.
- Close notifications and unrelated tabs.
- Never open GitHub secrets or Azure access tokens.
- Blur Azure account identifiers before publishing.
- Avoid background music and visual effects; the evidence should remain the
  focus.
