# Portfolio deployment

This profile deploys the existing Nordic Shopping architecture without changing the development or production configuration.

The deployment keeps both regions, all eight web applications, Front Door and WAF, SQL geo-replication, private networking, monitoring, workload identities, policies and the Azure budget. The existing architecture also creates staging slots for the primary customer and API applications, so Basic and Free App Service plans are deliberately excluded.

The qualification workflow selects two regions with available SQL capacity, the same slot-capable App Service SKU and enough Total Regional VMs. It checks the SQL administrator group, the deployment identity, provider registrations, existing resources and the short-lived cost estimate before running Azure provider validation and What-If.

No resources are created by qualification. The separate deployment workflow requires `DEPLOY-PORTFOLIO`, a successful qualification run from the same commit and GitHub environment approval. Cleanup requires `DELETE-PORTFOLIO` and only targets the exact Nordic Shopping development resource groups and regional Key Vaults selected by the profile.

The original `dev` and `prod` files and workflows are not used or changed.
