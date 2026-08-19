using '../../main.bicep'

param environmentName = 'prod'

param primaryLocation = 'westeurope'
param primaryRegionCode = 'weu'

param secondaryLocation = 'swedencentral'
param secondaryRegionCode = 'swc'

param owner = 'Amin Azad'
param costCenter = 'nordic-shopping'
param criticality = 'high'
param dataClassification = 'confidential'

param tags = {
  application: 'nordic-shopping'
  environment: 'prod'
  owner: 'Amin Azad'
  costCentre: 'nordic-shopping'
  dataClassification: 'confidential'
  criticality: 'high'
  managedBy: 'bicep'
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

param policyAuditEffect = 'Audit'
param enableResourceLocks = true
param enableKeyVaultPurgeProtection = true

param storageSkuName = 'Standard_LRS'
param storagePublicNetworkAccess = 'Disabled'
param storageSoftDeleteRetentionDays = 30
param storageContainerSoftDeleteRetentionDays = 14
param storageOldVersionRetentionDays = 30
param enableStorageDiagnostics = true

param sqlEntraAdminLogin = 'nshop-database-administrators'
param sqlEntraAdminObjectId = readEnvironmentVariable('SQL_ENTRA_ADMIN_OBJECT_ID')
param sqlEntraAdminTenantId = readEnvironmentVariable('AZURE_TENANT_ID')

param sqlDatabaseSkuName = 'GP_Gen5_2'
param sqlDatabaseSkuCapacity = 2
param primarySqlDatabaseZoneRedundant = true
param secondarySqlDatabaseZoneRedundant = false
param sqlDatabaseMaxSizeBytes = 34359738368
param sqlDatabaseBackupRetentionDays = 7
param sqlDatabaseBackupStorageRedundancy = 'Local'
param sqlFailoverPolicy = 'Manual'

param appServicePlanSkuName = 'P1v3'
param appServicePlanWorkerCount = 2
param appServicePlanZoneRedundant = true
param createAllStagingSlots = true

param autoscaleEnabled = true

param primaryAutoscaleMinimumCapacity = 2
param primaryAutoscaleDefaultCapacity = 2
param primaryAutoscaleMaximumCapacity = 4

param secondaryAutoscaleMinimumCapacity = 2
param secondaryAutoscaleDefaultCapacity = 2
param secondaryAutoscaleMaximumCapacity = 4

param enableAiServicesAccount = true
param aiServicesPublicNetworkAccess = 'Disabled'
param enableAiServicesDiagnostics = true
param enableAiModelDeployment = true
param aiModelDeploymentName = 'ops-assistant'
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

param enableLogAlerts = true
param enableAdministrativeOperationAlert = true
param enableActivityLogAlerts = true
param enableMonitorWorkbook = true

param applicationExceptionAlertThreshold = 5
param authenticationFailureAlertThreshold = 10
param privateAccessViolationAlertThreshold = 1
param administrativeOperationAlertThreshold = 1

param logOperationalSeverity = 2
param logSecuritySeverity = 1
