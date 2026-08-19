# Current Environment

My starting assumption is that Nordic Shopping currently runs everything from a small on-premises setup in Copenhagen. As this is a fictional case study, I do not have a real server inventory. I used the points below only as the starting position for my Azure design.

What I assumed:

- Around 35 employees, 40,000 customers and 150 vendors.
- Roughly 600 orders on a normal day.
- Customer Web, Vendor Portal, Admin Portal and one main API.
- The mobile apps use the same API, so I did not count them as server workloads.
- Windows-based application hosting.
- Microsoft SQL Server for customer, product, vendor and order data.
- Shared storage for images and other files.
- Active Directory for employee access.
- A local backup server.
- Connections to payment, email, SMS and delivery providers.
- Mainly manual application and infrastructure changes.

The biggest concern for me is that everything depends on one location. A site, internet, power or important hardware failure could affect the whole platform. The backup may also be in the same location, so having a backup would not necessarily protect the business from losing the site.

I also assumed that monitoring is separated between different servers and applications. This could make it difficult to understand what happened during an incident. Manual deployments and manually managed credentials could create similar problems.

Before doing this for a real company, I would need to check:

- how many physical servers and virtual machines actually exist;
- CPU, memory, disk space and normal usage;
- Windows and SQL Server versions;
- database size, growth and special SQL features;
- where files are stored and which applications use local disk;
- network ranges, firewall rules, DNS and certificates;
- user accounts, administrator access and service accounts;
- backup frequency, retention and the last successful restore test;
- normal traffic, busy periods and application response times;
- scheduled jobs and background processes;
- how releases and rollbacks currently work;
- credentials and requirements for external providers;
- data quality and which information really needs to be migrated.

The existing platform would need to stay available while the Azure environment was built and tested. I would also keep it available for rollback until the migration was confirmed as successful.
