using '../../main.bicep'

param environmentName = 'dev'
param primaryLocation = 'westeurope'
param secondaryLocation = 'swedencentral'

param owner = 'Amin Azad'
param costCenter = 'portfolio'
param criticality = 'low'
param dataClassification = 'internal'

param tags = {
  project: 'nordic-shopping-cloud-transformation'
  environment: 'dev'
  managedBy: 'bicep'
  owner: 'Amin Azad'
  costCenter: 'portfolio'
}
param budgetAmount = 16500
param budgetStartDate = '2026-08-01T00:00:00Z'
param budgetEndDate = '2031-08-01T00:00:00Z'

param budgetContactEmail = readEnvironmentVariable('BUDGET_ALERT_EMAIL')

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

param enableKeyVaultPurgeProtection = false

param storageSkuName = 'Standard_LRS'
param storagePublicNetworkAccess = 'Enabled'
param storageSoftDeleteRetentionDays = 7
param storageOldVersionRetentionDays = 30
param enableStorageDiagnostics = true

param sqlEntraAdminLogin = 'Amin Azad'
param sqlEntraAdminObjectId = readEnvironmentVariable('SQL_ENTRA_ADMIN_OBJECT_ID')
param sqlEntraAdminTenantId = 'ad58f8c3-bc65-4d29-947d-53190e993ba4'

param appServicePlanSkuName = 'B1'
param appServicePlanWorkerCount = 1
param appServicePlanZoneRedundant = false

param autoscaleEnabled = true

param primaryAutoscaleMinimumCapacity = 1
param primaryAutoscaleDefaultCapacity = 1
param primaryAutoscaleMaximumCapacity = 2

param secondaryAutoscaleMinimumCapacity = 1
param secondaryAutoscaleDefaultCapacity = 1
param secondaryAutoscaleMaximumCapacity = 2

param enableAiModelDeployment = false
param aiModelDeploymentName = 'gpt-4o-mini'
param aiModelName = 'gpt-4o-mini'
param aiModelVersion = '2024-07-18'
param aiModelDeploymentSkuName = 'Standard'
param aiModelDeploymentCapacity = 1

param wafApiRateLimitThreshold = 600
param wafAuthenticationRateLimitThreshold = 30
