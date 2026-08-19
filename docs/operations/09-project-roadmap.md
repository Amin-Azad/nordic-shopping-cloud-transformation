# Project Roadmap

This is the order I planned for the Nordic Shopping cloud transformation. The timing is only an estimate because a real schedule would depend on the application, team, Azure subscription and discovery results.

## Weeks 1–2: Understand the current environment

- Confirm the business and technical requirements.
- Inventory the applications, database, files and identities.
- Document network connections and external providers.
- Check backups and the existing recovery process.
- Measure current traffic and performance.
- Record the main migration and security risks.

I would not finalize production sizing until the important discovery questions were answered.

## Weeks 3–4: Prepare the engineering foundation

- Organize the repository and Bicep modules.
- Create separate development and production parameters.
- Set up GitHub OIDC identities.
- Add Bicep formatting, linting and build checks.
- Create the What-If and guarded deployment workflow.
- Confirm Azure providers, permissions, regional availability and quota.

## Weeks 5–7: Build the Azure foundation

- Create resource groups, networks and subnets.
- Configure private DNS and private endpoints.
- Create App Service plans and application resources.
- Create SQL, Storage and Key Vault.
- Add managed identities and RBAC.
- Configure Front Door, WAF and monitoring.
- Deploy and test the development environment first.

## Weeks 8–10: Prepare and test the applications

- Remove dependencies on local server storage.
- Move configuration and secrets to the correct services.
- Add authentication and server-side authorization.
- Add application health endpoints.
- Configure deployment slots and rollback.
- Test SQL, Storage, Key Vault and external integrations.
- Run application and infrastructure security checks.

This phase requires real application source code. Infrastructure alone cannot prove the customer and vendor workflows.

## Weeks 11–12: Rehearse migration

- Create repeatable database and file migration scripts.
- Run the first rehearsal.
- Compare record counts, business totals and file checksums.
- Correct data and timing problems.
- Run a second production-like rehearsal.
- Confirm the cutover and rollback conditions.

## Week 13: Test operations and recovery

- Test alerts and responder routing.
- Test backup and restore.
- Run a regional failover and failback exercise.
- Measure recovery time and possible data loss.
- Review orders, inventory and payments after recovery.
- Update the runbooks using the test results.

## Week 14: Production migration

- Confirm the change freeze and communication plan.
- Complete the final data synchronization.
- Validate identities, business data and integrations.
- Move traffic gradually.
- Monitor errors, performance and spending.
- Roll back if the agreed checks fail.

## Weeks 15–16: Stabilize and review

- Keep the old environment available for rollback.
- Fix issues found after cutover.
- Review performance and Azure cost.
- Adjust resource sizes using measured data.
- Complete documentation and operational handover.
- Remove old systems only after the business and data are confirmed.

The sixteen-week schedule is a planning estimate, not a completed delivery record. A real project could take longer if discovery finds application, identity, data or subscription limitations.
