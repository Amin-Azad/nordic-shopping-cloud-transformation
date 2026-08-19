# Business Case

## Business situation

Nordic Shopping is a fictional e-commerce company based in Copenhagen. In this case study, it has around 35 employees, 40,000 registered customers, 150 active vendors and approximately 600 orders per day.

For planning, I assumed that the company wants to grow over the next three years toward 250,000 registered customers, 800 vendors and around 5,000 daily orders while expanding into Sweden and Norway.

I assumed that its applications were running from one small on-premises environment. This makes the business dependent on one location and makes recovery, scaling and regular software releases difficult.

The company also plans to grow into other Nordic markets. The current setup may support today’s workload, but it would become harder to manage as the number of customers, vendors and orders increases.

## Why a change is needed

The main problem is the dependency on a single physical location. A serious hardware, network or site failure could interrupt all online services. Adding capacity would also require purchasing and configuring more hardware.

The existing approach creates several concerns:

- no tested regional recovery;
- limited ability to scale during busy periods;
- manual and inconsistent infrastructure changes;
- limited centralized monitoring;
- slower and riskier software releases;
- increasing maintenance as the business grows.

Keeping the current environment would avoid an immediate migration, but it would leave these problems unresolved. Moving the same servers to Azure virtual machines would reduce the physical-site dependency, but the company would still need to manage operating systems, patching and server capacity.

## Proposed direction

My proposal is to move the main e-commerce platform to managed Azure services.

The design would use West Europe as the primary region and Sweden Central as the recovery region. At a high level, it would include:

- Azure Front Door and Web Application Firewall for incoming traffic;
- Azure App Service for the customer, vendor, administration and API applications;
- Azure SQL Database with a secondary database for recovery;
- Storage accounts and Key Vault for files and secrets;
- private networking for important data services;
- centralized monitoring and alerts;
- Bicep and GitHub Actions for repeatable infrastructure deployment.

I selected managed Azure services instead of virtual machines or Kubernetes because they reduce infrastructure maintenance and are more suitable for the assumed size of the company.

## Expected value

The proposed transformation should:

- reduce dependency on one physical location;
- provide a practical recovery option in another Azure region;
- make infrastructure changes repeatable;
- improve monitoring and incident visibility;
- support safer and more frequent releases;
- provide a clearer path for future growth.

The first design is intended for the current workload. It should be reviewed and scaled based on real performance measurements rather than assuming that it can automatically support every future growth target.

## Cost boundary

The estimated Azure cost for the proposed production design is approximately **DKK 15,000 per month**. I used **DKK 16,500 per month** as the upper planning boundary for normal operation.

A separate estimated allowance of **DKK 14,000–38,000** may be required during implementation for temporary development environments, migration rehearsals, testing and parallel operation.

These are planning estimates, not an Azure invoice or an approved company budget. They exclude VAT, employee or consultant costs, Microsoft 365 licences, payment-provider charges and other third-party services. The prices would need to be checked again before a real implementation.

Based on the case-study assumptions, I believe a managed Azure platform with regional recovery provides a reasonable balance between cost, resilience and operational complexity.
