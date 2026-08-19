# Business Requirements

These are the main business requirements I considered for the Nordic Shopping cloud transformation. They are based on a fictional company with around 35 employees, 40,000 customers, 150 vendors and approximately 600 orders per day.

1. Customers should be able to register, sign in, browse products, use the shopping cart, place orders and follow their order status.

2. The existing customer and vendor mobile applications should continue using the main API.

3. Vendors should be able to manage their own products, prices, stock and orders.

4. One vendor must not be able to view or change another vendor’s data.

5. Employees should receive access based on their work, such as customer support, finance or administration.

6. Important employee and administrator actions should be recorded for later review.

7. The business should not depend completely on one physical location.

8. The platform should have a recovery option in another Azure region.

9. Customer-facing services should target at least 99.9% monthly availability.

10. After a major regional failure, the target should be to restore the service within 60 minutes and limit possible data loss to 15 minutes.

11. Backup, restore, regional failover and failback should be tested before using the platform in production.

12. Normal application releases should not cause significant interruption for customers.

13. The company should be able to release changes weekly or when needed.

14. Infrastructure changes should be repeatable and reviewed before deployment.

15. Applications, infrastructure, security events and costs should be monitored from one place.

16. The responsible people should receive alerts when an important service fails or when spending increases unexpectedly.

17. Customer, vendor and company data should be encrypted and protected through least-privilege access.

18. Secrets and connection information should not be stored directly inside application code or deployment workflows.

19. The platform should support GDPR needs such as controlled access, retention, correction and deletion of personal data.

20. Payment-card details should remain with the external payment provider and should not be stored in the platform.

21. Retried payment or order requests should not create duplicate transactions.

22. Uploaded files should be checked before they are treated as trusted content.

23. The first design should support the current workload and allow later scaling based on measured usage.

24. The estimated production cost should remain around DKK 15,000 per month, with DKK 16,500 used as the upper planning boundary for a normal month.

25. Temporary development, testing and migration costs should be tracked separately.

26. Kubernetes, active-active databases, microservices and other complex services are not required in the first design unless there is a clear business reason.

27. Before a real implementation, the assumptions, workload, security needs, recovery targets, costs and Azure subscription limits would need to be confirmed with the relevant stakeholders.
