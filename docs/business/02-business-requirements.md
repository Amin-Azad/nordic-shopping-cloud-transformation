# Business Requirements

I started by writing down what Nordic Shopping would need from the new platform. These are case-study assumptions, not requirements collected from a real company.

The customer side needs to keep the normal shopping journey: account access, product search, cart, checkout, orders and order tracking. The existing mobile app should continue using the same API.

Vendors need to manage their products, prices, stock and orders. The important point here is separation. A vendor should only see its own business data.

Employees also need different levels of access. Support, finance and administration do not need the same permissions. Important administrative actions should be logged so they can be reviewed later.

The platform should support the current workload first and allow the company to scale toward the three-year business target. This does not mean that the initial Azure resource sizes are already proven for 250,000 customers or 5,000 daily orders.

From the business side, my main requirements were:

- remove the dependency on one physical location;
- keep the service available during normal application releases;
- provide recovery in another Azure region;
- aim for 99.9% monthly availability;
- target recovery within 60 minutes with no more than 15 minutes of possible data loss;
- make infrastructure changes repeatable;
- improve monitoring and alerting;
- allow the platform to grow without rebuilding everything immediately.

Customer, vendor and company data needs to be protected. Access should follow least privilege, secrets should not be kept in code, and payment-card details should stay with the payment provider. The design should also support basic GDPR needs such as controlled access, retention, correction and deletion.

For operations, I wanted one place to view application and infrastructure health. The responsible person should receive an alert if an important service fails or if the Azure cost starts increasing unexpectedly.

The cost target I used was around DKK 15,000 per month for production, with DKK 16,500 as the upper planning boundary for a normal month. Development, testing and migration costs would be tracked separately.

I did not consider Kubernetes, active-active databases or a microservices conversion necessary for the first version. They would add cost and complexity without a clear need at the assumed company size.

For a real project, these requirements would need to be discussed with the business, application, security and operations teams before treating them as final.
