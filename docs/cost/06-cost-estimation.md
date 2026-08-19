# Azure Sizing and Cost Estimate

I prepared this estimate after deciding the initial Azure services and resource sizes for the Nordic Shopping design.

The sizes are starting assumptions for the fictional workload of around 40,000 customers, 150 vendors and 600 daily orders. They would need to be tested and adjusted before a real production deployment.

## Initial sizing decisions

The cost baseline is for the initial production design, not for the three-year growth target. If the workload grows toward 250,000 customers and 5,000 daily orders, the resources and monthly cost will need to be recalculated using load-test and production data.

| Area | Initial decision | Reason |
| --- | --- | --- |
| Primary region | West Europe | Main production region for the case study |
| Recovery region | Sweden Central | Separate Azure region for recovery |
| Public traffic | Azure Front Door Standard with WAF | Global entry point, web protection and regional routing |
| Primary App Service plan | Linux P1v3, two workers | Supports production features, staging slots and more than one active worker |
| Primary scaling | Two to four workers | Allows horizontal scaling during higher demand |
| Recovery App Service plan | Linux P1v3, two workers | Keeps standby capacity available without waiting for scale-up |
| Applications | Four App Services per region | Separate Customer Web, API, Vendor Portal and Admin Portal |
| Database | Azure SQL General Purpose, provisioned two vCores | Starting size for the assumed transactional workload |
| Database recovery | Equal-size geo-secondary | Keeps the recovery database compatible with the primary |
| Storage | One Standard StorageV2 account per region | Stores application files with a separate regional account |
| Secrets | One Standard Key Vault per region | Separates primary and recovery secrets |
| Private access | SQL, Blob and Key Vault private endpoints | Keeps important data services off the public network |
| Monitoring | Log Analytics and Application Insights | Central place for application and infrastructure telemetry |
| Log retention | 30-day starting point | Provides useful operational history without assuming long retention |
| AI | Small pay-as-you-go allowance | Optional operations use without provisioned capacity |

I selected P1v3 instead of a Basic App Service plan because the production design needs staging slots, multiple workers and stronger production capabilities.

The recovery region uses the same App Service SKU and SQL size as the primary region. This costs more than a minimal standby, but it reduces the number of changes required during recovery.

The final sizes should be based on load tests and real usage. Registered-customer count alone is not enough to size App Service or SQL.

## Estimated monthly Azure cost

| Area | Costed configuration | Monthly estimate |
| --- | --- | ---: |
| Primary application hosting | Two P1v3 workers in West Europe | DKK 2,900 |
| Recovery application hosting | Two P1v3 workers in Sweden Central | DKK 2,900 |
| Primary database | General Purpose SQL, two vCores | DKK 2,600 |
| Recovery database | Equal-size SQL geo-secondary | DKK 2,400 |
| Front Door and WAF | Standard tier with moderate traffic | DKK 650 |
| Storage and data protection | Two StorageV2 accounts | DKK 350 |
| Monitoring and alerts | Log Analytics, Application Insights and alerts | DKK 700 |
| Private connectivity | Planned private endpoints | DKK 350 |
| Key Vault and Private DNS | Two vaults and required DNS zones | DKK 50 |
| Security and file scanning | Planned production allowance | DKK 350 |
| Optional AI usage | Pay-as-you-go allowance | DKK 300 |
| Bandwidth and regional transfer | Normal traffic and replication allowance | DKK 350 |
| Other small platform costs | Minor usage allowance | DKK 50 |
| **Estimated Azure service cost** | | **DKK 13,950** |
| Planning contingency | Usage and price variation | DKK 1,050 |
| **Monthly planning baseline** | | **DKK 15,000** |

I will use DKK 16,500 as the upper planning boundary for a normal month. The extra DKK 1,500 provides headroom for traffic, monitoring and other usage-based changes. It is not a target to spend.

The main cost is keeping App Service and SQL capacity in both regions. A single-region design would be cheaper, but it would not meet the planned regional recovery requirement.

## Temporary project cost

I estimate another DKK 14,000–38,000 for temporary Azure usage during implementation and migration. This may include:

- development and test environments;
- production-like migration rehearsals;
- temporary data copies;
- load, security and recovery testing;
- a short period of parallel operation.

The estimate excludes salaries, consultants, VAT, Microsoft 365, payment-provider charges, SMS, email, delivery services and other third-party systems.

## Cost controls

I plan to use:

- smaller resource sizes in development;
- tags for environment, workload and ownership;
- Azure budget and forecast alerts;
- expiry dates for temporary resources;
- regular review of App Service, SQL, Storage, logs and bandwidth.

Budget alerts will provide warnings. They will not automatically stop production resources.

Some values cover capabilities that remain planned, including file scanning, Blob replication and optional AI usage. Their estimates should be removed or adjusted if they are not included in the final implementation.

Before a real deployment, I would check these figures again using the current Azure Pricing Calculator, confirmed regions, selected subscription and measured workload data.
