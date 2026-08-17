targetScope = 'subscription'

metadata name = 'Nordic Shopping Cloud Transformation'
metadata description = 'Subscription-level orchestration template for Nordic Shopping Azure infrastructure.'

@description('Deployment environment.')
param environmentName 'dev' | 'test' | 'prod'

@description('Primary Azure region.')
param primaryLocation string = 'westeurope'

@description('Short code used in names for the primary Azure region.')
param primaryRegionCode string

@description('Secondary Azure region used for disaster recovery.')
param secondaryLocation string = 'swedencentral'

@description('Short code used in names for the secondary Azure region.')
param secondaryRegionCode string

@description('Azure regions permitted by the location governance policy.')
param allowedLocations array = [
  primaryLocation
  secondaryLocation
]

@description('Tag names required on supported Azure resources.')
param requiredTagNames array = [
  'application'
  'environment'
  'owner'
  'costCentre'
  'dataClassification'
  'criticality'
  'managedBy'
]

@description('Controls whether governance policies audit resources or are disabled.')
@allowed([
  'Audit'
  'Disabled'
])
param policyAuditEffect string = 'Audit'
@description('Enables CanNotDelete locks. Enabled by default only in production.')
param enableResourceLocks bool = environmentName == 'prod'

@description('Short project code used in Azure resource names.')
@minLength(2)
@maxLength(10)
param projectCode string = 'nshop'

@description('Team or business owner responsible for the environment.')
@minLength(1)
param owner string

@description('Cost center used for Azure cost allocation and reporting.')
@minLength(1)
param costCenter string

@description('Business criticality classification for the environment.')
@minLength(1)
param criticality string

@description('Data classification applied to the environment.')
@minLength(1)
param dataClassification string

@description('Tags applied to resources deployed by this project.')
param tags object = {
  application: 'nordic-shopping'
  environment: environmentName
  owner: owner
  costCentre: costCenter
  dataClassification: dataClassification
  criticality: criticality
  managedBy: 'bicep'
}

@description('Monthly Azure budget amount in the subscription billing currency.')
@minValue(1)
param budgetAmount int

@description('Budget monitoring start date.')
param budgetStartDate string

@description('Budget monitoring end date.')
param budgetEndDate string

@description('Email address that receives budget notifications.')
@secure()
param budgetContactEmail string

@description('Optional Action Group resource IDs for budget notifications.')
param budgetActionGroupIds array = []

@description('Email receivers for operational alerts.')
param operationalEmailReceivers array = []

@description('Email receivers for security alerts.')
param securityEmailReceivers array = []

@description('Email receivers for cost and budget alerts.')
param costEmailReceivers array = []

@description('Creates the optional AI operations managed identity.')
param enableAiOperationsIdentity bool = false

@description('Enables Key Vault purge protection. Use false only for temporary development environments.')
param enableKeyVaultPurgeProtection bool = true

@description('Storage account redundancy.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
])
param storageSkuName string = 'Standard_LRS'

@description('Controls access through the public Storage endpoint.')
@allowed([
  'Enabled'
  'Disabled'
])
param storagePublicNetworkAccess string = 'Disabled'

@description('Deleted blob retention period.')
@minValue(1)
@maxValue(365)
param storageSoftDeleteRetentionDays int = 30

@description('Deleted container retention period.')
@minValue(1)
@maxValue(365)
param storageContainerSoftDeleteRetentionDays int = 14

@description('Retention period for previous blob versions.')
@minValue(1)
@maxValue(365)
param storageOldVersionRetentionDays int = 30

@description('Enables Storage diagnostic settings.')
param enableStorageDiagnostics bool = true

@description('Display name of the Microsoft Entra SQL administrator.')
param sqlEntraAdminLogin string

@description('Object ID of the Microsoft Entra SQL administrator.')
param sqlEntraAdminObjectId string

@description('Tenant ID containing the Microsoft Entra SQL administrator.')
param sqlEntraAdminTenantId string

param sqlDatabaseName string = 'sqldb-${projectCode}-${environmentName}'
param sqlDatabaseSkuName string = 'GP_Gen5_2'
param sqlDatabaseSkuCapacity int = 2
param sqlDatabaseZoneRedundant bool = true
param sqlDatabaseMaxSizeBytes int = 34359738368
param sqlDatabaseBackupRetentionDays int = 7
param sqlDatabaseBackupStorageRedundancy string = 'Local'
@description('Failover policy for the SQL failover group.')
@allowed([
  'Automatic'
  'Manual'
])
param sqlFailoverPolicy string = 'Manual'

param appServicePlanSkuName string = 'P1v3'
@minValue(1)
param appServicePlanWorkerCount int = 2
param appServicePlanZoneRedundant bool = true
@description('Creates staging slots for every application in both regions.')
param createAllStagingSlots bool = environmentName == 'prod'

param autoscaleEnabled bool = true
//primary region
@minValue(1)
param primaryAutoscaleMinimumCapacity int = 2
@minValue(1)
param primaryAutoscaleDefaultCapacity int = 2
@minValue(1)
param primaryAutoscaleMaximumCapacity int = 4

//Secondary region
@minValue(1)
param secondaryAutoscaleMinimumCapacity int = 2
@minValue(1)
param secondaryAutoscaleDefaultCapacity int = 2
@minValue(1)
param secondaryAutoscaleMaximumCapacity int = 4

@description('Deploys the optional Azure AI Services account in the primary region.')
param enableAiServicesAccount bool = true
@description('Controls access through the public AI Services endpoint.')
@allowed([
  'Enabled'
  'Disabled'
])
param aiServicesPublicNetworkAccess string = 'Disabled'

@description('Enables AI Services diagnostic settings.')
param enableAiServicesDiagnostics bool = true

param enableAiModelDeployment bool = false
param aiModelDeploymentName string = 'gpt-4o-mini'
param aiModelName string = 'gpt-4o-mini'
param aiModelVersion string = '2024-07-18'

@allowed([
  'Standard'
  'GlobalStandard'
  'DataZoneStandard'
])
param aiModelDeploymentSkuName string = 'Standard'

@minValue(1)
param aiModelDeploymentCapacity int = 1

@description('Maximum API requests allowed per client IP per minute.')
@minValue(1)
param wafApiRateLimitThreshold int

@description('Maximum authentication requests allowed per client IP per five minutes.')
@minValue(1)
param wafAuthenticationRateLimitThreshold int

@description('Object ID of the platform administrators Entra security group.')
param platformAdministratorsGroupObjectId string

@description('Object ID of the developers Entra security group.')
param developersGroupObjectId string

@description('Object ID of the operations Entra security group.')
param operationsGroupObjectId string

@description('Object ID of the security readers Entra security group.')
param securityReadersGroupObjectId string

@description('Object ID of the cost readers Entra security group.')
param costReadersGroupObjectId string

@description('Object ID of the database administrators Entra security group.')
param databaseAdministratorsGroupObjectId string

@description('Object ID of the auditors Entra security group.')
param auditorsGroupObjectId string

@description('Enables Azure Monitor metric alerts.')
param enableMetricAlerts bool = true

@description('Minimum acceptable Front Door origin health percentage.')
param frontDoorOriginHealthThreshold int = 90

@description('Maximum acceptable Front Door 5xx percentage.')
param frontDoor5xxThreshold int = 5

@description('Maximum acceptable App Service plan CPU percentage.')
param appServiceCpuAlertThreshold int = 80

@description('Maximum Web App HTTP 5xx responses in five minutes.')
param appService5xxAlertThreshold int = 10

@description('Maximum acceptable SQL Database CPU percentage.')
param sqlCpuAlertThreshold int = 80

@description('Maximum SQL connection failures in five minutes.')
param sqlConnectionFailureThreshold int = 5

@description('Maximum acceptable SQL Database storage percentage.')
param sqlStorageAlertThreshold int = 80

@description('Minimum acceptable Storage availability percentage.')
param storageAvailabilityThreshold int = 99

@description('Minimum acceptable Key Vault availability percentage.')
param keyVaultAvailabilityThreshold int = 99

@description('Maximum Key Vault failed requests in five minutes.')
param keyVaultFailureThreshold int = 5

@allowed([
  0
  1
  2
  3
  4
])
param availabilityAlertSeverity int = 1

@allowed([
  0
  1
  2
  3
  4
])
param performanceAlertSeverity int = 2

@allowed([
  0
  1
  2
  3
  4
])
param securityAlertSeverity int = 1

param enableLogAlerts bool = false
param enableAdministrativeOperationAlert bool = false
param enableActivityLogAlerts bool = true
@description('Deploys the shared Azure Monitor Workbook operations dashboard.')
param enableMonitorWorkbook bool = true

param applicationExceptionAlertThreshold int = 5
param authenticationFailureAlertThreshold int = 10
param privateAccessViolationAlertThreshold int = 1
param administrativeOperationAlertThreshold int = 1

@allowed([0, 1, 2, 3, 4])
param logOperationalSeverity int = 2

@allowed([0, 1, 2, 3, 4])
param logSecuritySeverity int = 1

var sqlFailoverGroupName = 'fog-${projectCode}-${environmentName}'

var logRetentionInDays = environmentName == 'prod' ? 90 : 31
var logDailyQuotaGb = environmentName == 'prod' ? -1 : 1
var applicationInsightsSamplingPercentage = 100

// West Europe network ranges
var primaryVnetAddressPrefix = '10.10.0.0/16'
var primaryAppSubnetPrefix = '10.10.1.0/24'
var primaryPrivateEndpointSubnetPrefix = '10.10.2.0/24'

// Sweden Central network ranges
var secondaryVnetAddressPrefix = '10.20.0.0/16'
var secondaryAppSubnetPrefix = '10.20.1.0/24'
var secondaryPrivateEndpointSubnetPrefix = '10.20.2.0/24'

//key-vault name
var primaryKeyVaultName = 'kv-${projectCode}-${environmentName}-${primaryRegionCode}'
var secondaryKeyVaultName = 'kv-${projectCode}-${environmentName}-${secondaryRegionCode}'

// Azure AI Services account names must be globally unique.
var aiServicesAccountName = 'oai-${projectCode}-${environmentName}-${take(uniqueString(subscription().id, primaryLocation), 6)}'

// Storage account names must be globally unique and contain only lowercase letters and numbers.
var primaryStorageAccountName = 'st${take(projectCode, 5)}${environmentName}${uniqueString(subscription().id, primaryLocation)}'
var secondaryStorageAccountName = 'st${take(projectCode, 5)}${environmentName}${uniqueString(subscription().id, secondaryLocation)}'

var storageContainerNames = [
  'product-assets'
  'quarantine'
  'documents'
  'invoices'
  'exports'
  'operations'
]

// SQL logical server names must be globally unique.
var primarySqlServerName = 'sql-${projectCode}-${environmentName}-${primaryRegionCode}-${take(uniqueString(subscription().id, primaryLocation), 6)}'
var secondarySqlServerName = 'sql-${projectCode}-${environmentName}-${secondaryRegionCode}-${take(uniqueString(subscription().id, secondaryLocation), 6)}'

var webAppWorkloads = [
  {
    name: 'customer'
    createStagingSlot: true
  }
  {
    name: 'vendor'
    createStagingSlot: false
  }
  {
    name: 'admin'
    createStagingSlot: false
  }
  {
    name: 'api'
    createStagingSlot: true
  }
]

module resourceGroupsModule './modules/governance/resource-groups.bicep' = {
  name: 'deploy-resource-groups-${environmentName}'
  params: {
    environment: environmentName
    projectCode: projectCode
    primaryLocation: primaryLocation
    primaryRegionCode: primaryRegionCode
    secondaryLocation: secondaryLocation
    secondaryRegionCode: secondaryRegionCode
    owner: owner
    costCenter: costCenter
    criticality: criticality
    dataClassification: dataClassification
  }
}

module managedIdentitiesModule './modules/identity/managed-identities.bicep' = {
  name: 'deploy-managed-identities-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-security')
  params: {
    location: primaryLocation
    automationIdentityName: 'id-${projectCode}-${environmentName}-automation'
    aiOperationsIdentityName: 'id-${projectCode}-${environmentName}-ai-ops'
    enableAiOperationsIdentity: enableAiOperationsIdentity
    tags: tags
  }
  dependsOn: [
    resourceGroupsModule
  ]
}

module logAnalyticsModule './modules/monitoring/log-analytics.bicep' = {
  name: 'deploy-log-analytics-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-monitor')
  params: {
    location: primaryLocation
    workspaceName: 'log-${projectCode}-${environmentName}'
    retentionInDays: logRetentionInDays
    dailyQuotaGb: logDailyQuotaGb
    tags: tags
  }
  dependsOn: [
    resourceGroupsModule
  ]
}

module sqlFailoverGroupModule './modules/data/sql-failover-group.bicep' = {
  name: 'deploy-sql-failover-group-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-${primaryRegionCode}')
  params: {
    failoverGroupName: sqlFailoverGroupName
    primaryServerName: primaryRegionalPlatformModule.outputs.sqlServerName
    primaryDatabaseId: primaryRegionalPlatformModule.outputs.sqlDatabaseId
    secondaryServerId: secondaryRegionalPlatformModule.outputs.sqlServerId
    failoverPolicy: sqlFailoverPolicy
    failoverGracePeriodMinutes: 60
    tags: tags
  }
}

module applicationInsightsModule './modules/monitoring/application-insights.bicep' = {
  name: 'deploy-application-insights-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-monitor')
  params: {
    location: primaryLocation
    applicationInsightsName: 'appi-${projectCode}-${environmentName}'
    logAnalyticsWorkspaceResourceId: logAnalyticsModule.outputs.workspaceId
    samplingPercentage: applicationInsightsSamplingPercentage
    tags: tags
  }
}
module actionGroupsModule './modules/monitoring/action-groups.bicep' = {
  name: 'deploy-action-groups-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-monitor')
  params: {
    environmentName: environmentName
    projectCode: projectCode
    tags: tags
    operationalEmailReceivers: operationalEmailReceivers
    securityEmailReceivers: securityEmailReceivers
    costEmailReceivers: costEmailReceivers
  }
  dependsOn: [
    resourceGroupsModule
  ]
}
module privateDnsZonesModule './modules/networking/private-dns-zones.bicep' = {
  name: 'deploy-private-dns-zones-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-network')
  params: {
    tags: tags
  }
  dependsOn: [
    resourceGroupsModule
  ]
}

module primaryRegionalPlatformModule './orchestration/regional-platform.bicep' = {
  name: 'deploy-regional-platform-${environmentName}-${primaryRegionCode}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-${primaryRegionCode}')
  params: {
    environmentName: environmentName
    regionRole: 'primary'
    projectCode: projectCode
    regionCode: primaryRegionCode
    location: primaryLocation
    networkResourceGroupName: 'rg-${projectCode}-${environmentName}-network'

    virtualNetworkAddressPrefix: primaryVnetAddressPrefix
    appServiceSubnetAddressPrefix: primaryAppSubnetPrefix
    privateEndpointSubnetAddressPrefix: primaryPrivateEndpointSubnetPrefix

    storageAccountName: primaryStorageAccountName
    storageSkuName: storageSkuName
    storagePublicNetworkAccess: storagePublicNetworkAccess
    enableStorageDiagnostics: enableStorageDiagnostics
    storageContainerNames: storageContainerNames

    storageSoftDeleteRetentionDays: storageSoftDeleteRetentionDays
    storageContainerSoftDeleteRetentionDays: storageContainerSoftDeleteRetentionDays
    storageOldVersionRetentionDays: storageOldVersionRetentionDays

    keyVaultName: primaryKeyVaultName
    enableKeyVaultPurgeProtection: enableKeyVaultPurgeProtection

    sqlServerName: primarySqlServerName
    sqlEntraAdminLogin: sqlEntraAdminLogin
    sqlEntraAdminObjectId: sqlEntraAdminObjectId
    sqlEntraAdminTenantId: sqlEntraAdminTenantId
    sqlDatabaseName: sqlDatabaseName
    sqlDatabaseSkuName: sqlDatabaseSkuName
    sqlDatabaseSkuCapacity: sqlDatabaseSkuCapacity
    sqlDatabaseZoneRedundant: sqlDatabaseZoneRedundant
    sqlDatabaseMaxSizeBytes: sqlDatabaseMaxSizeBytes
    sqlDatabaseBackupRetentionDays: sqlDatabaseBackupRetentionDays
    sqlDatabaseBackupStorageRedundancy: sqlDatabaseBackupStorageRedundancy

    appServicePlanSkuName: appServicePlanSkuName
    appServicePlanWorkerCount: appServicePlanWorkerCount
    appServicePlanZoneRedundant: appServicePlanZoneRedundant
    createAllStagingSlots: createAllStagingSlots
    workloads: webAppWorkloads
    autoscaleEnabled: autoscaleEnabled
    autoscaleMinimumCapacity: primaryAutoscaleMinimumCapacity
    autoscaleDefaultCapacity: primaryAutoscaleDefaultCapacity
    autoscaleMaximumCapacity: primaryAutoscaleMaximumCapacity

    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.workspaceId
    applicationInsightsConnectionString: applicationInsightsModule.outputs.connectionString

    blobPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.blob
    keyVaultPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.keyVault
    sqlPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.sql
    azureOpenAIPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.azureOpenAI

    deployAiServices: enableAiServicesAccount
    aiServicesAccountName: aiServicesAccountName
    aiServicesPublicNetworkAccess: aiServicesPublicNetworkAccess
    enableAiServicesDiagnostics: enableAiServicesDiagnostics
    enableAiModelDeployment: enableAiModelDeployment
    aiModelDeploymentName: aiModelDeploymentName
    aiModelName: aiModelName
    aiModelVersion: aiModelVersion
    aiModelDeploymentSkuName: aiModelDeploymentSkuName
    aiModelDeploymentCapacity: aiModelDeploymentCapacity

    tags: tags
  }
  dependsOn: [
    resourceGroupsModule
  ]
}

module secondaryRegionalPlatformModule './orchestration/regional-platform.bicep' = {
  name: 'deploy-regional-platform-${environmentName}-${secondaryRegionCode}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-${secondaryRegionCode}')
  params: {
    environmentName: environmentName
    regionRole: 'secondary'
    projectCode: projectCode
    regionCode: secondaryRegionCode
    location: secondaryLocation
    networkResourceGroupName: 'rg-${projectCode}-${environmentName}-network'

    virtualNetworkAddressPrefix: secondaryVnetAddressPrefix
    appServiceSubnetAddressPrefix: secondaryAppSubnetPrefix
    privateEndpointSubnetAddressPrefix: secondaryPrivateEndpointSubnetPrefix

    storageAccountName: secondaryStorageAccountName
    storageSkuName: storageSkuName
    storagePublicNetworkAccess: storagePublicNetworkAccess
    storageSoftDeleteRetentionDays: storageSoftDeleteRetentionDays
    storageContainerSoftDeleteRetentionDays: storageContainerSoftDeleteRetentionDays
    storageOldVersionRetentionDays: storageOldVersionRetentionDays
    enableStorageDiagnostics: enableStorageDiagnostics
    storageContainerNames: storageContainerNames

    keyVaultName: secondaryKeyVaultName
    enableKeyVaultPurgeProtection: enableKeyVaultPurgeProtection

    sqlDatabaseName: sqlDatabaseName
    sqlServerName: secondarySqlServerName
    sqlEntraAdminLogin: sqlEntraAdminLogin
    sqlEntraAdminObjectId: sqlEntraAdminObjectId
    sqlEntraAdminTenantId: sqlEntraAdminTenantId
    sqlDatabaseSkuName: sqlDatabaseSkuName
    sqlDatabaseSkuCapacity: sqlDatabaseSkuCapacity
    sqlDatabaseZoneRedundant: sqlDatabaseZoneRedundant
    sqlDatabaseMaxSizeBytes: sqlDatabaseMaxSizeBytes
    sqlDatabaseBackupRetentionDays: sqlDatabaseBackupRetentionDays
    sqlDatabaseBackupStorageRedundancy: sqlDatabaseBackupStorageRedundancy

    appServicePlanSkuName: appServicePlanSkuName
    appServicePlanWorkerCount: appServicePlanWorkerCount
    appServicePlanZoneRedundant: appServicePlanZoneRedundant
    createAllStagingSlots: createAllStagingSlots
    workloads: webAppWorkloads
    autoscaleEnabled: autoscaleEnabled
    autoscaleMinimumCapacity: secondaryAutoscaleMinimumCapacity
    autoscaleDefaultCapacity: secondaryAutoscaleDefaultCapacity
    autoscaleMaximumCapacity: secondaryAutoscaleMaximumCapacity

    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.workspaceId
    applicationInsightsConnectionString: applicationInsightsModule.outputs.connectionString

    blobPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.blob
    keyVaultPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.keyVault
    sqlPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.sql
    azureOpenAIPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.azureOpenAI

    deployAiServices: false
    tags: tags
  }
  dependsOn: [
    resourceGroupsModule
  ]
}

module privateDnsVnetLinksModule './modules/networking/private-dns-vnet-links.bicep' = {
  name: 'deploy-private-dns-vnet-links-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-network')
  params: {
    primaryVirtualNetworkId: primaryRegionalPlatformModule.outputs.virtualNetworkId
    secondaryVirtualNetworkId: secondaryRegionalPlatformModule.outputs.virtualNetworkId
  }
}
module globalPlatformModule './orchestration/global-platform.bicep' = {
  name: 'deploy-global-platform-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-global')
  params: {
    environmentName: environmentName
    wafPolicyName: 'waf-${projectCode}-${environmentName}'
    frontDoorProfileName: 'afd-${projectCode}-${environmentName}'
    endpointNamePrefix: 'afd-${projectCode}-${environmentName}-${take(uniqueString(subscription().id), 6)}'
    workloads: [
      {
        name: 'web'
        primaryHostName: primaryRegionalPlatformModule.outputs.webApps[0].hostname
        secondaryHostName: secondaryRegionalPlatformModule.outputs.webApps[0].hostname
      }
      {
        name: 'vendor'
        primaryHostName: primaryRegionalPlatformModule.outputs.webApps[1].hostname
        secondaryHostName: secondaryRegionalPlatformModule.outputs.webApps[1].hostname
      }
      {
        name: 'admin'
        primaryHostName: primaryRegionalPlatformModule.outputs.webApps[2].hostname
        secondaryHostName: secondaryRegionalPlatformModule.outputs.webApps[2].hostname
      }
      {
        name: 'api'
        primaryHostName: primaryRegionalPlatformModule.outputs.webApps[3].hostname
        secondaryHostName: secondaryRegionalPlatformModule.outputs.webApps[3].hostname
      }
    ]
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.workspaceId
    wafApiRateLimitThreshold: wafApiRateLimitThreshold
    wafAuthenticationRateLimitThreshold: wafAuthenticationRateLimitThreshold
    healthProbePath: '/health/ready'
    enableDiagnostics: true
    tags: tags
  }
}

module metricAlertsModule './modules/monitoring/metric-alerts.bicep' = {
  name: 'deploy-metric-alerts-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-monitor')
  params: {
    environmentName: environmentName
    frontDoorProfileId: globalPlatformModule.outputs.frontDoorProfileId

    appServicePlanIds: [
      primaryRegionalPlatformModule.outputs.appServicePlanId
      secondaryRegionalPlatformModule.outputs.appServicePlanId
    ]

    webAppIds: [
      primaryRegionalPlatformModule.outputs.webApps[0].webAppId
      primaryRegionalPlatformModule.outputs.webApps[1].webAppId
      primaryRegionalPlatformModule.outputs.webApps[2].webAppId
      primaryRegionalPlatformModule.outputs.webApps[3].webAppId

      secondaryRegionalPlatformModule.outputs.webApps[0].webAppId
      secondaryRegionalPlatformModule.outputs.webApps[1].webAppId
      secondaryRegionalPlatformModule.outputs.webApps[2].webAppId
      secondaryRegionalPlatformModule.outputs.webApps[3].webAppId
    ]

    sqlDatabaseIds: [
      primaryRegionalPlatformModule.outputs.sqlDatabaseId
      resourceId(
        'rg-${projectCode}-${environmentName}-${secondaryRegionCode}',
        'Microsoft.Sql/servers/databases',
        secondaryRegionalPlatformModule.outputs.sqlServerName,
        sqlDatabaseName
      )
    ]

    storageAccountIds: [
      primaryRegionalPlatformModule.outputs.storageAccountId
      secondaryRegionalPlatformModule.outputs.storageAccountId
    ]

    keyVaultIds: [
      primaryRegionalPlatformModule.outputs.keyVaultId
      secondaryRegionalPlatformModule.outputs.keyVaultId
    ]

    operationalActionGroupId: actionGroupsModule.outputs.operationalActionGroupId
    securityActionGroupId: actionGroupsModule.outputs.securityActionGroupId
    enabled: enableMetricAlerts

    frontDoorOriginHealthThreshold: frontDoorOriginHealthThreshold
    frontDoor5xxThreshold: frontDoor5xxThreshold
    appServiceCpuThreshold: appServiceCpuAlertThreshold
    appService5xxThreshold: appService5xxAlertThreshold
    sqlCpuThreshold: sqlCpuAlertThreshold
    sqlConnectionFailureThreshold: sqlConnectionFailureThreshold
    sqlStorageThreshold: sqlStorageAlertThreshold
    storageAvailabilityThreshold: storageAvailabilityThreshold
    keyVaultAvailabilityThreshold: keyVaultAvailabilityThreshold
    keyVaultFailureThreshold: keyVaultFailureThreshold

    availabilitySeverity: availabilityAlertSeverity
    performanceSeverity: performanceAlertSeverity
    securitySeverity: securityAlertSeverity
  }
  dependsOn: [
    sqlFailoverGroupModule
  ]
}
module logAlertsModule './modules/monitoring/log-alerts.bicep' = {
  name: 'deploy-log-alerts-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-monitor')
  params: {
    environmentName: environmentName
    location: primaryLocation
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.workspaceId
    operationalActionGroupId: actionGroupsModule.outputs.operationalActionGroupId
    securityActionGroupId: actionGroupsModule.outputs.securityActionGroupId
    tags: tags

    enableLogAlerts: enableLogAlerts
    enableAdministrativeOperationAlert: enableAdministrativeOperationAlert

    applicationExceptionThreshold: applicationExceptionAlertThreshold
    authenticationFailureThreshold: authenticationFailureAlertThreshold
    privateAccessViolationThreshold: privateAccessViolationAlertThreshold
    administrativeOperationThreshold: administrativeOperationAlertThreshold

    operationalSeverity: logOperationalSeverity
    securitySeverity: logSecuritySeverity
  }
}
module serviceHealthAlertsModule './modules/monitoring/service-health-alerts.bicep' = {
  name: 'deploy-service-health-alerts-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-monitor')
  params: {
    environmentName: environmentName
    operationalActionGroupId: actionGroupsModule.outputs.operationalActionGroupId
    securityActionGroupId: actionGroupsModule.outputs.securityActionGroupId
    tags: tags
    enabled: enableActivityLogAlerts
  }
}

module monitorWorkbookModule './modules/monitoring/monitor-workbook.bicep' = if (enableMonitorWorkbook) {
  name: 'deploy-monitor-workbook-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-monitor')
  params: {
    location: primaryLocation
    workbookName: guid(subscription().id, projectCode, environmentName, 'operations-workbook')
    displayName: 'Nordic Shopping ${toUpper(environmentName)} Operations Dashboard'
    environmentName: environmentName
    applicationInsightsId: applicationInsightsModule.outputs.applicationInsightsId
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.workspaceId
    frontDoorProfileId: globalPlatformModule.outputs.frontDoorProfileId

    appServicePlanIds: [
      primaryRegionalPlatformModule.outputs.appServicePlanId
      secondaryRegionalPlatformModule.outputs.appServicePlanId
    ]

    primaryWebAppIds: [
      primaryRegionalPlatformModule.outputs.webApps[0].webAppId
      primaryRegionalPlatformModule.outputs.webApps[1].webAppId
      primaryRegionalPlatformModule.outputs.webApps[2].webAppId
      primaryRegionalPlatformModule.outputs.webApps[3].webAppId
    ]

    secondaryWebAppIds: [
      secondaryRegionalPlatformModule.outputs.webApps[0].webAppId
      secondaryRegionalPlatformModule.outputs.webApps[1].webAppId
      secondaryRegionalPlatformModule.outputs.webApps[2].webAppId
      secondaryRegionalPlatformModule.outputs.webApps[3].webAppId
    ]

    sqlDatabaseIds: [
      primaryRegionalPlatformModule.outputs.sqlDatabaseId
      resourceId(
        'rg-${projectCode}-${environmentName}-${secondaryRegionCode}',
        'Microsoft.Sql/servers/databases',
        secondaryRegionalPlatformModule.outputs.sqlServerName,
        sqlDatabaseName
      )
    ]

    primaryLocation: primaryLocation
    secondaryLocation: secondaryLocation
    tags: tags
  }
  dependsOn: [
    metricAlertsModule
    logAlertsModule
    serviceHealthAlertsModule
  ]
}
module primaryOriginLockdownModule './modules/compute/app-service-origin-lockdown.bicep' = {
  name: 'deploy-origin-lockdown-${environmentName}-${primaryRegionCode}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-${primaryRegionCode}')
  params: {
    webAppNames: [
      for (workload, index) in webAppWorkloads: primaryRegionalPlatformModule.outputs.webApps[index].webAppName
    ]
    frontDoorId: globalPlatformModule.outputs.frontDoorId
  }
}

module secondaryOriginLockdownModule './modules/compute/app-service-origin-lockdown.bicep' = {
  name: 'deploy-origin-lockdown-${environmentName}-${secondaryRegionCode}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-${secondaryRegionCode}')
  params: {
    webAppNames: [
      for (workload, index) in webAppWorkloads: secondaryRegionalPlatformModule.outputs.webApps[index].webAppName
    ]
    frontDoorId: globalPlatformModule.outputs.frontDoorId
  }
}
module primaryWorkloadRbacModule './modules/identity/workload-rbac.bicep' = {
  name: 'deploy-workload-rbac-${environmentName}-${primaryRegionCode}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-${primaryRegionCode}')
  params: {
    apiPrincipalId: primaryRegionalPlatformModule.outputs.webApps[3].principalId
    enableApiDataAccess: true
    storageAccountName: primaryRegionalPlatformModule.outputs.storageAccountName
    blobContainerNames: storageContainerNames
    keyVaultName: primaryRegionalPlatformModule.outputs.keyVaultName

    automationPrincipalId: managedIdentitiesModule.outputs.automationIdentityPrincipalId
    enableAutomationAccess: true
    webAppNames: [
      for (workload, index) in webAppWorkloads: primaryRegionalPlatformModule.outputs.webApps[index].webAppName
    ]

    aiOperationsPrincipalId: managedIdentitiesModule.outputs.aiOperationsIdentityPrincipalId
    enableAiAccess: enableAiOperationsIdentity && enableAiServicesAccount
    aiServicesAccountName: primaryRegionalPlatformModule.outputs.aiServicesAccountName
  }
}

module secondaryWorkloadRbacModule './modules/identity/workload-rbac.bicep' = {
  name: 'deploy-workload-rbac-${environmentName}-${secondaryRegionCode}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-${secondaryRegionCode}')
  params: {
    apiPrincipalId: secondaryRegionalPlatformModule.outputs.webApps[3].principalId
    enableApiDataAccess: true
    storageAccountName: secondaryRegionalPlatformModule.outputs.storageAccountName
    blobContainerNames: storageContainerNames
    keyVaultName: secondaryRegionalPlatformModule.outputs.keyVaultName

    automationPrincipalId: managedIdentitiesModule.outputs.automationIdentityPrincipalId
    enableAutomationAccess: true
    webAppNames: [
      for (workload, index) in webAppWorkloads: secondaryRegionalPlatformModule.outputs.webApps[index].webAppName
    ]
  }
}

module monitoringWorkloadRbacModule './modules/identity/workload-rbac.bicep' = {
  name: 'deploy-workload-rbac-${environmentName}-monitor'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-monitor')
  params: {
    aiOperationsPrincipalId: managedIdentitiesModule.outputs.aiOperationsIdentityPrincipalId
    enableMonitoringAccess: enableAiOperationsIdentity
    logAnalyticsWorkspaceName: logAnalyticsModule.outputs.workspaceName
  }
}

module humanRbacModule './modules/identity/human-rbac.bicep' = {
  name: 'deploy-human-rbac-${environmentName}'
  params: {
    environmentName: environmentName

    platformAdministratorsGroupObjectId: platformAdministratorsGroupObjectId
    developersGroupObjectId: developersGroupObjectId
    operationsGroupObjectId: operationsGroupObjectId
    securityReadersGroupObjectId: securityReadersGroupObjectId
    costReadersGroupObjectId: costReadersGroupObjectId
    databaseAdministratorsGroupObjectId: databaseAdministratorsGroupObjectId
    auditorsGroupObjectId: auditorsGroupObjectId

    projectResourceGroupNames: [
      'rg-${projectCode}-${environmentName}-global'
      'rg-${projectCode}-${environmentName}-${primaryRegionCode}'
      'rg-${projectCode}-${environmentName}-${secondaryRegionCode}'
      'rg-${projectCode}-${environmentName}-network'
      'rg-${projectCode}-${environmentName}-monitor'
      'rg-${projectCode}-${environmentName}-security'
    ]

    operationsResourceGroupNames: [
      'rg-${projectCode}-${environmentName}-global'
      'rg-${projectCode}-${environmentName}-${primaryRegionCode}'
      'rg-${projectCode}-${environmentName}-${secondaryRegionCode}'
      'rg-${projectCode}-${environmentName}-monitor'
    ]

    primaryResourceGroupName: 'rg-${projectCode}-${environmentName}-${primaryRegionCode}'
    secondaryResourceGroupName: 'rg-${projectCode}-${environmentName}-${secondaryRegionCode}'
    monitoringResourceGroupName: 'rg-${projectCode}-${environmentName}-monitor'

    primaryWebAppNames: [
      for (workload, index) in webAppWorkloads: primaryRegionalPlatformModule.outputs.webApps[index].webAppName
    ]

    secondaryWebAppNames: [
      for (workload, index) in webAppWorkloads: secondaryRegionalPlatformModule.outputs.webApps[index].webAppName
    ]

    primarySqlServerName: primaryRegionalPlatformModule.outputs.sqlServerName
    secondarySqlServerName: secondaryRegionalPlatformModule.outputs.sqlServerName
    logAnalyticsWorkspaceName: logAnalyticsModule.outputs.workspaceName
  }
  dependsOn: [
    resourceGroupsModule
  ]
}
module policyAssignmentsModule './modules/governance/policy-assignments.bicep' = {
  name: 'deploy-policy-assignments-${environmentName}'
  params: {
    environment: environmentName
    allowedLocations: allowedLocations
    requiredTagNames: requiredTagNames
    auditEffect: policyAuditEffect
  }
}

module budgetModule './modules/governance/budget.bicep' = {
  name: 'deploy-budget-${environmentName}'
  params: {
    budgetName: 'budget-${projectCode}-${environmentName}-monthly'
    budgetAmount: budgetAmount
    startDate: budgetStartDate
    endDate: budgetEndDate
    contactEmail: budgetContactEmail
    actionGroupIds: union(budgetActionGroupIds, [
      actionGroupsModule.outputs.costActionGroupId
    ])
  }
}
module primaryResourceLocksModule './modules/governance/resource-locks.bicep' = if (enableResourceLocks) {
  name: 'deploy-resource-locks-${environmentName}-${primaryRegionCode}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-${primaryRegionCode}')
  params: {
    environmentName: environmentName
    enableResourceLocks: true

    keyVaultName: primaryRegionalPlatformModule.outputs.keyVaultName
    storageAccountName: primaryRegionalPlatformModule.outputs.storageAccountName
    sqlServerName: primaryRegionalPlatformModule.outputs.sqlServerName

    webAppNames: [
      for (workload, index) in webAppWorkloads: primaryRegionalPlatformModule.outputs.webApps[index].webAppName
    ]

    appServicePlanNames: [
      primaryRegionalPlatformModule.outputs.appServicePlanName
    ]
  }
}
module secondaryResourceLocksModule './modules/governance/resource-locks.bicep' = if (enableResourceLocks) {
  name: 'deploy-resource-locks-${environmentName}-${secondaryRegionCode}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-${secondaryRegionCode}')
  params: {
    environmentName: environmentName
    enableResourceLocks: true

    keyVaultName: secondaryRegionalPlatformModule.outputs.keyVaultName
    storageAccountName: secondaryRegionalPlatformModule.outputs.storageAccountName
    sqlServerName: secondaryRegionalPlatformModule.outputs.sqlServerName

    webAppNames: [
      for (workload, index) in webAppWorkloads: secondaryRegionalPlatformModule.outputs.webApps[index].webAppName
    ]

    appServicePlanNames: [
      secondaryRegionalPlatformModule.outputs.appServicePlanName
    ]
  }
}
module globalResourceLocksModule './modules/governance/resource-locks.bicep' = if (enableResourceLocks) {
  name: 'deploy-resource-locks-${environmentName}-global'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-global')
  params: {
    environmentName: environmentName
    enableResourceLocks: true
    frontDoorProfileName: globalPlatformModule.outputs.frontDoorProfileName
  }
}
module monitoringResourceLocksModule './modules/governance/resource-locks.bicep' = if (enableResourceLocks) {
  name: 'deploy-resource-locks-${environmentName}-monitor'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-monitor')
  params: {
    environmentName: environmentName
    enableResourceLocks: true
    logAnalyticsWorkspaceName: logAnalyticsModule.outputs.workspaceName
  }
}

// Outputs
output deploymentEnvironment string = environmentName
output primaryRegion string = primaryLocation
output secondaryRegion string = secondaryLocation
output deploymentTags object = tags

//budget outputs
output budgetResourceId string = budgetModule.outputs.budgetId
output budgetName string = budgetModule.outputs.deployedBudgetName

//policy assignment outputs
output deployedPolicyAssignmentCount int = policyAssignmentsModule.outputs.policyAssignmentCount

//log analytics outputs
output logAnalyticsWorkspaceId string = logAnalyticsModule.outputs.workspaceId
output logAnalyticsWorkspaceName string = logAnalyticsModule.outputs.workspaceName
output logAnalyticsWorkspaceCustomerId string = logAnalyticsModule.outputs.workspaceCustomerId
output logAnalyticsWorkspaceLocation string = logAnalyticsModule.outputs.workspaceLocation

//Application Insights outputs
output applicationInsightsId string = applicationInsightsModule.outputs.applicationInsightsId
output applicationInsightsName string = applicationInsightsModule.outputs.applicationInsightsName
output applicationInsightsConnectionString string = applicationInsightsModule.outputs.connectionString

//Action group outputs
output operationalActionGroupId string = actionGroupsModule.outputs.operationalActionGroupId
output securityActionGroupId string = actionGroupsModule.outputs.securityActionGroupId
output costActionGroupId string = actionGroupsModule.outputs.costActionGroupId

//NSG outputs
output primaryAppServiceNsgId string = primaryRegionalPlatformModule.outputs.appServiceNsgId
output primaryPrivateEndpointNsgId string = primaryRegionalPlatformModule.outputs.privateEndpointNsgId
output secondaryAppServiceNsgId string = secondaryRegionalPlatformModule.outputs.appServiceNsgId
output secondaryPrivateEndpointNsgId string = secondaryRegionalPlatformModule.outputs.privateEndpointNsgId

//VNET outputs
output primaryVirtualNetworkId string = primaryRegionalPlatformModule.outputs.virtualNetworkId
output primaryAppServiceSubnetId string = primaryRegionalPlatformModule.outputs.appServiceSubnetId
output primaryPrivateEndpointSubnetId string = primaryRegionalPlatformModule.outputs.privateEndpointSubnetId

output secondaryVirtualNetworkId string = secondaryRegionalPlatformModule.outputs.virtualNetworkId
output secondaryAppServiceSubnetId string = secondaryRegionalPlatformModule.outputs.appServiceSubnetId
output secondaryPrivateEndpointSubnetId string = secondaryRegionalPlatformModule.outputs.privateEndpointSubnetId

// Managed identity outputs
output automationIdentityResourceId string = managedIdentitiesModule.outputs.automationIdentityResourceId
output automationIdentityPrincipalId string = managedIdentitiesModule.outputs.automationIdentityPrincipalId
output automationIdentityClientId string = managedIdentitiesModule.outputs.automationIdentityClientId

output aiOperationsIdentityResourceId string = managedIdentitiesModule.outputs.aiOperationsIdentityResourceId
output aiOperationsIdentityPrincipalId string = managedIdentitiesModule.outputs.aiOperationsIdentityPrincipalId
output aiOperationsIdentityClientId string = managedIdentitiesModule.outputs.aiOperationsIdentityClientId

//Storage accounts output
output primaryStorageAccountId string = primaryRegionalPlatformModule.outputs.storageAccountId
output primaryStorageAccountName string = primaryRegionalPlatformModule.outputs.storageAccountName
output primaryBlobEndpoint string = primaryRegionalPlatformModule.outputs.storageBlobEndpoint

output secondaryStorageAccountId string = secondaryRegionalPlatformModule.outputs.storageAccountId
output secondaryStorageAccountName string = secondaryRegionalPlatformModule.outputs.storageAccountName
output secondaryBlobEndpoint string = secondaryRegionalPlatformModule.outputs.storageBlobEndpoint

// SQL logical server outputs
output primarySqlServerId string = primaryRegionalPlatformModule.outputs.sqlServerId
output primarySqlServerName string = primaryRegionalPlatformModule.outputs.sqlServerName
output primarySqlServerFullyQualifiedDomainName string = primaryRegionalPlatformModule.outputs.sqlServerFullyQualifiedDomainName

output secondarySqlServerId string = secondaryRegionalPlatformModule.outputs.sqlServerId
output secondarySqlServerName string = secondaryRegionalPlatformModule.outputs.sqlServerName
output secondarySqlServerFullyQualifiedDomainName string = secondaryRegionalPlatformModule.outputs.sqlServerFullyQualifiedDomainName
// SQL database outputs
output primarySqlDatabaseId string = primaryRegionalPlatformModule.outputs.sqlDatabaseId
output primarySqlDatabaseName string = primaryRegionalPlatformModule.outputs.sqlDatabaseName

// Key Vault outputs
output primaryKeyVaultId string = primaryRegionalPlatformModule.outputs.keyVaultId
output primaryKeyVaultName string = primaryRegionalPlatformModule.outputs.keyVaultName
output secondaryKeyVaultId string = secondaryRegionalPlatformModule.outputs.keyVaultId
output secondaryKeyVaultName string = secondaryRegionalPlatformModule.outputs.keyVaultName

//app service plan outputs
output primaryAppServicePlanId string = primaryRegionalPlatformModule.outputs.appServicePlanId
output primaryAppServicePlanName string = primaryRegionalPlatformModule.outputs.appServicePlanName
output primaryAppServiceLocation string = primaryRegionalPlatformModule.outputs.location

output secondaryAppServicePlanId string = secondaryRegionalPlatformModule.outputs.appServicePlanId
output secondaryAppServicePlanName string = secondaryRegionalPlatformModule.outputs.appServicePlanName
output secondaryAppServiceLocation string = secondaryRegionalPlatformModule.outputs.location

// Web App outputs
output primaryWebApps array = [
  for (workload, index) in webAppWorkloads: {
    workload: workload.name
    webAppId: primaryRegionalPlatformModule.outputs.webApps[index].webAppId
    webAppName: primaryRegionalPlatformModule.outputs.webApps[index].webAppName
    hostname: primaryRegionalPlatformModule.outputs.webApps[index].hostname
    principalId: primaryRegionalPlatformModule.outputs.webApps[index].principalId
    stagingSlotName: primaryRegionalPlatformModule.outputs.webApps[index].stagingSlotName
  }
]

output secondaryWebApps array = [
  for (workload, index) in webAppWorkloads: {
    workload: workload.name
    webAppId: secondaryRegionalPlatformModule.outputs.webApps[index].webAppId
    webAppName: secondaryRegionalPlatformModule.outputs.webApps[index].webAppName
    hostname: secondaryRegionalPlatformModule.outputs.webApps[index].hostname
    principalId: secondaryRegionalPlatformModule.outputs.webApps[index].principalId
  }
]
// AI Services outputs
output aiServicesAccountId string = primaryRegionalPlatformModule.outputs.aiServicesAccountId
output aiServicesAccountName string = primaryRegionalPlatformModule.outputs.aiServicesAccountName
output aiServicesEndpoint string = primaryRegionalPlatformModule.outputs.aiServicesEndpoint
output aiServicesPrincipalId string = primaryRegionalPlatformModule.outputs.aiServicesPrincipalId
