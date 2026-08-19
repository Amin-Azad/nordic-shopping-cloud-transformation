# Migration Strategy

This is how I plan to move Nordic Shopping from the assumed on-premises environment to Azure. Because this is a fictional case study, the plan will need to be updated if real applications and data become available.

I will begin with discovery rather than immediately moving the workloads. I first need to understand:

- the application runtimes and dependencies;
- local files, sessions and scheduled jobs;
- SQL Server version, size and special features;
- customer, vendor and employee identities;
- network connections, DNS and certificates;
- payment, email, SMS and delivery integrations;
- current traffic and performance;
- backups and the existing recovery process.

After discovery, I will check whether the applications can run on Linux App Service. Any dependency on local storage or server-specific configuration will need to be removed or replaced.

The migration will happen in stages:

1. Prepare the Azure development environment.

2. Configure networking, identity, secrets and monitoring.

3. Update and test the applications for Azure.

4. Connect the applications to Azure SQL, Storage and Key Vault.

5. Create repeatable scripts for database and file migration.

6. Run the first migration rehearsal to identify missing dependencies and data problems.

7. Correct the process and run a second production-like rehearsal.

8. Compare record counts, important business totals and file checksums.

9. Prepare the production environment and agree on the final migration window.

10. Pause important changes in the old platform and complete the final data synchronization.

11. Test customer access, vendor separation, orders, payments and external integrations.

12. Move public traffic only after the technical and business checks pass.

Before the final migration, I will define when to stop and roll back. Possible rollback reasons include:

- incorrect or missing business data;
- customers or vendors receiving the wrong access;
- payment or order-processing failures;
- unacceptable application performance;
- a security control not working;
- the recovery process not being ready.

The old environment will remain available during the migration. After cutover, I will keep it for rollback and temporary read-only access until the Azure platform is stable and the data has been confirmed.

A real migration will also require named owners, user communication, an agreed downtime window and approval from the people responsible for the applications and business data.
