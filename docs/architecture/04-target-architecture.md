# Target Architecture

This is the Azure architecture I planned for the Nordic Shopping case study. My aim is to reduce the dependency on one physical location while keeping the design manageable for a relatively small company.

I chose managed Azure services instead of virtual machines or Kubernetes because the assumed team should not need to spend most of its time maintaining servers or a container platform.

## Overall design

The production platform will use West Europe as the primary region and Sweden Central as the recovery region.

Public traffic will enter through Azure Front Door Standard. Front Door will provide TLS, Web Application Firewall protection, health checks and routing between the two regions.

The platform will have four application workloads:

- Customer Web;
- Nordic API;
- Vendor Portal;
- Admin Portal.

Each workload will have its own Linux App Service so that it can be configured and deployed separately. The applications in each region will share an App Service plan to keep the starting cost lower.

The portals and web application will not connect directly to the database or Storage. They will use the Nordic API, which will remain the main boundary for business logic and data access.

The initial resource sizes are based on the current assumed workload of 40,000 customers, 150 vendors and approximately 600 daily orders. App Service can scale horizontally, but application behaviour, SQL capacity and external-provider limits must also be tested before increasing traffic.

The three-year planning target is 250,000 customers, 800 vendors and around 5,000 daily orders. Reaching that level may require more App Service workers, a larger SQL tier or separate compute for the API. I have not treated the starting design as proven for that target.

## Primary and recovery regions

West Europe will run the active production workload. The App Service plan will start with two workers and will be able to scale when usage increases.

Sweden Central will contain a warm standby environment. It will have the same application structure and two standing App Service workers so that it can receive traffic without first waiting for new compute capacity.

Azure SQL Database will have a primary database in West Europe and a geo-secondary database in Sweden Central. The primary database is planned to use zone redundancy.

Front Door will normally send traffic to West Europe. Traffic can be moved to Sweden Central after the recovery database and applications have been checked.

Database promotion and regional traffic activation will remain manual decisions. I do not want the deployment pipeline to declare a disaster or accept possible data loss automatically.

The design targets recovery within 60 minutes and no more than 15 minutes of possible data loss. These targets will need to be tested before production use.

## Networking

Each region will have its own virtual network.

I planned two main subnets in each region:

- one delegated subnet for App Service VNet integration;
- one subnet for private endpoints.

SQL Database, Blob Storage and Key Vault will use private endpoints and Private DNS. Their public network access will be disabled in production.

The address ranges will be different in each region so that the networks can be connected later without overlapping addresses.

## Identity and security

GitHub Actions will connect to Azure through OIDC instead of using a stored Azure client secret.

Each App Service will use a managed identity when accessing supported Azure services. Application secrets that cannot use managed identity will be stored in Key Vault.

I also planned separate Entra groups for platform administration, development, operations, security review, cost review, database administration and auditing.

Front Door WAF will protect public traffic. App Service access restrictions will be used to reduce direct access to the application origins.

Customer authentication, vendor separation and employee authorization will still need to be enforced inside the applications. Deploying Azure infrastructure alone will not provide these business controls.

## Data and files

Azure SQL Database will store the main transactional data.

Each region will also have a Storage account for application files. Important files may be replicated to the recovery region, but the exact replication rules should be decided after the data is classified.

Uploaded files should be placed in quarantine and checked before being moved to trusted storage. This requires application logic as well as Azure security services.

Key Vault will store secrets, certificates and other protected configuration.

## Monitoring

Application Insights and Log Analytics will collect application and infrastructure telemetry.

Azure Monitor alerts will cover important areas such as:

- application availability and HTTP errors;
- App Service capacity;
- SQL health and replication;
- resource health;
- deployment failures;
- security events;
- unexpected cost increases.

An Azure Monitor workbook will provide a basic operational view. Alert recipients and response procedures will need to be confirmed before production.

## Deployment approach

The infrastructure will be written as modular Bicep. Development and production will use the same main modules with different parameter files.

GitHub Actions will be used to:

- validate and build the Bicep files;
- preview infrastructure changes with What-If;
- deploy after review and confirmation;
- remove development resources through a separate guarded cleanup process.

Production will use stronger settings than development, including larger App Service plans, staging slots, additional resilience, longer log retention, resource locks and stronger Key Vault protection.

## Kept outside the first version

I did not include Kubernetes, virtual machines, API Management, Service Bus, Redis, Microsoft Sentinel or active-active database writes in the first design.

These services could be useful later, but I would add them only if real workload, security or operational evidence showed a need.

Custom domains, application health endpoints, file-replication rules, malware-scanning workflow and the final identity setup will also need to be completed and tested before production use.
