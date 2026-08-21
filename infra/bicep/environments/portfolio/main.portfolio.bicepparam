using '../../main.bicep'

param environmentName = 'dev'
param primaryLocation = readEnvironmentVariable('PORTFOLIO_PRIMARY_LOCATION')
param primaryRegionCode = readEnvironmentVariable('PORTFOLIO_PRIMARY_REGION_CODE')
param secondaryLocation = readEnvironmentVariable('PORTFOLIO_SECONDARY_LOCATION')
param secondaryRegionCode = readEnvironmentVariable('PORTFOLIO_SECONDARY_REGION_CODE')

param owner = 'Amin Azad'
param costCenter = 'portfolio'
param criticality = 'low'
param dataClassification = 'internal'

param tags = {
  application: 'nordic-shopping'
  environment: 'dev'
  owner: 'Amin Azad'
  costCentre: 'portfolio'
  dataClassification: 'internal'
  criticality: 'low'
  managedBy: 'bicep'
  deploymentProfile: 'portfolio'
}

param budgetAmount = 900
param budgetStartDate = readEnvironmentVariable('PORTFOLIO_BUDGET_START_DATE')
param budgetEndDate = readEnvironmentVariable('PORTFOLIO_BUDGET_END_DATE')
param budgetContactEmail = readEnvironmentVariable('BUDGET_ALERT_EMAIL')

param policyAuditEffect = 'Audit'
param sqlFailoverPolicy = 'Manual'

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
param enableResourceLocks = false

param storageSkuName = 'Standard_LRS'
param storagePublicNetworkAccess = 'Enabled'
param enableStorageDiagnostics = true
param storageSoftDeleteRetentionDays = 7
param storageContainerSoftDeleteRetentionDays = 7
param storageOldVersionRetentionDays = 30

param sqlEntraAdminLogin = readEnvironmentVariable('PORTFOLIO_SQL_ADMIN_LOGIN')
param sqlEntraAdminObjectId = readEnvironmentVariable('SQL_ENTRA_ADMIN_OBJECT_ID')
param sqlEntraAdminTenantId = readEnvironmentVariable('AZURE_TENANT_ID')
param sqlDatabaseSkuName = 'GP_S_Gen5_1'
param sqlDatabaseSkuCapacity = 1
param primarySqlDatabaseZoneRedundant = false
param secondarySqlDatabaseZoneRedundant = false

param appServicePlanSkuName = readEnvironmentVariable('PORTFOLIO_APP_SERVICE_SKU')
param appServicePlanWorkerCount = 1
param appServicePlanZoneRedundant = false
param createAllStagingSlots = false
param autoscaleEnabled = false
param primaryAutoscaleMinimumCapacity = 1
param primaryAutoscaleDefaultCapacity = 1
param primaryAutoscaleMaximumCapacity = 1
param secondaryAutoscaleMinimumCapacity = 1
param secondaryAutoscaleDefaultCapacity = 1
param secondaryAutoscaleMaximumCapacity = 1

param enableAiServicesAccount = false
param aiServicesPublicNetworkAccess = 'Enabled'
param enableAiModelDeployment = false
param aiModelDeploymentName = 'gpt-4o-mini'
param aiModelName = 'gpt-4o-mini'
param aiModelVersion = '2024-07-18'
param aiModelDeploymentSkuName = 'Standard'
param aiModelDeploymentCapacity = 1

param wafApiRateLimitThreshold = 600
param wafAuthenticationRateLimitThreshold = 30

param platformAdministratorsGroupObjectId = readEnvironmentVariable('PLATFORM_ADMINISTRATORS_GROUP_OBJECT_ID')
param developersGroupObjectId = readEnvironmentVariable('DEVELOPERS_GROUP_OBJECT_ID')
param operationsGroupObjectId = readEnvironmentVariable('OPERATIONS_GROUP_OBJECT_ID')
param securityReadersGroupObjectId = readEnvironmentVariable('SECURITY_READERS_GROUP_OBJECT_ID')
param costReadersGroupObjectId = readEnvironmentVariable('COST_READERS_GROUP_OBJECT_ID')
param databaseAdministratorsGroupObjectId = readEnvironmentVariable('DATABASE_ADMINISTRATORS_GROUP_OBJECT_ID')
param auditorsGroupObjectId = readEnvironmentVariable('AUDITORS_GROUP_OBJECT_ID')

param enableMetricAlerts = true
param frontDoorOriginHealthThreshold = 90
param frontDoor5xxThreshold = 5
param appServiceCpuAlertThreshold = 80
param appService5xxAlertThreshold = 10
param sqlCpuAlertThreshold = 80
param sqlConnectionFailureThreshold = 5
param sqlStorageAlertThreshold = 80
param storageAvailabilityThreshold = 99
param keyVaultAvailabilityThreshold = 99
param keyVaultFailureThreshold = 5
param availabilityAlertSeverity = 1
param performanceAlertSeverity = 2
param securityAlertSeverity = 1
param enableLogAlerts = false
param enableAdministrativeOperationAlert = false
param enableActivityLogAlerts = true
param applicationExceptionAlertThreshold = 5
param authenticationFailureAlertThreshold = 10
param privateAccessViolationAlertThreshold = 1
param administrativeOperationAlertThreshold = 1
param logOperationalSeverity = 2
param logSecuritySeverity = 1
