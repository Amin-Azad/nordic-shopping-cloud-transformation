using '../../main.minimal.bicep'

// ---------------------------------------------------------------------------
// Minimal profile: one region, one web app, no Front Door, no secondary region.
// Every secret-adjacent value comes from the environment so nothing identifying
// is committed. The validation workflow supplies placeholders.
// ---------------------------------------------------------------------------

param environmentName = 'dev'
param projectCode = 'nshop'

param location = readEnvironmentVariable('MINIMAL_LOCATION', 'swedencentral')
param regionCode = readEnvironmentVariable('MINIMAL_REGION_CODE', 'sdc')

param owner = readEnvironmentVariable('MINIMAL_OWNER', 'platform-owner')
param costCenter = 'portfolio'
param criticality = 'low'
param dataClassification = 'internal'

param tags = {
  application: 'nordic-shopping'
  environment: 'dev'
  owner: readEnvironmentVariable('MINIMAL_OWNER', 'platform-owner')
  costCentre: 'portfolio'
  dataClassification: 'internal'
  criticality: 'low'
  managedBy: 'bicep'
  deploymentProfile: 'minimal'
}

// ---- Networking -----------------------------------------------------------

param virtualNetworkAddressPrefix = '10.20.0.0/16'
param appServiceSubnetAddressPrefix = '10.20.1.0/24'
param privateEndpointSubnetAddressPrefix = '10.20.2.0/24'

// ---- Workload -------------------------------------------------------------
// One web app. B1 is the smallest tier with Always On, and it needs no staging
// slot, which is what lets this profile fit inside a sandbox subscription.

param webAppWorkloads = [
  {
    name: 'api'
    createStagingSlot: false
  }
]

param appServicePlanSkuName = readEnvironmentVariable('MINIMAL_APP_SERVICE_SKU', 'B1')
param appServicePlanWorkerCount = 1

// No Front Door in this profile, so the app must accept direct ingress.
param allowDirectAppServiceIngress = true

// ---- Data -----------------------------------------------------------------

param storageSkuName = 'Standard_LRS'
param storagePublicNetworkAccess = 'Disabled'
param storageContainerNames = [
  'product-images'
  'order-documents'
]

// Purge protection would block Key Vault deletion for 90 days after cleanup.
param enableKeyVaultPurgeProtection = false

// Must be a security-enabled GROUP. sql-server.bicep sets principalType 'Group',
// so a user or guest-user object ID is rejected by Azure.
param sqlEntraAdminLogin = readEnvironmentVariable('MINIMAL_SQL_ADMIN_LOGIN')
param sqlEntraAdminObjectId = readEnvironmentVariable('SQL_ENTRA_ADMIN_OBJECT_ID')
param sqlEntraAdminTenantId = readEnvironmentVariable('AZURE_TENANT_ID')

param sqlDatabaseName = 'sqldb-orders'
param sqlDatabaseSkuName = 'GP_S_Gen5_1'
param sqlDatabaseSkuCapacity = 1
param sqlDatabaseMaxSizeBytes = 34359738368
param sqlDatabaseBackupRetentionDays = 7
param sqlDatabaseBackupStorageRedundancy = 'Local'

// ---- Monitoring -----------------------------------------------------------

param logRetentionInDays = 30
param logDailyQuotaGb = 1

param operationalEmailReceivers = [
  {
    name: 'platform-owner'
    emailAddress: readEnvironmentVariable('OPERATIONAL_ALERT_EMAIL')
  }
]

param securityEmailReceivers = [
  {
    name: 'security-owner'
    emailAddress: readEnvironmentVariable('SECURITY_ALERT_EMAIL')
  }
]

param costEmailReceivers = [
  {
    name: 'cost-owner'
    emailAddress: readEnvironmentVariable('COST_ALERT_EMAIL')
  }
]

param enableMetricAlerts = true
param enableAvailabilityTest = true

// ---- Governance -----------------------------------------------------------

param policyAuditEffect = 'Audit'

param budgetAmount = 300
param budgetStartDate = readEnvironmentVariable('MINIMAL_BUDGET_START_DATE')
param budgetEndDate = readEnvironmentVariable('MINIMAL_BUDGET_END_DATE')
param budgetContactEmail = readEnvironmentVariable('BUDGET_ALERT_EMAIL')
