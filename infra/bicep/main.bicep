targetScope = 'subscription'

metadata name = 'Nordic Shopping Cloud Transformation'
metadata description = 'Subscription-level orchestration template for Nordic Shopping Azure infrastructure.'

@description('Deployment environment.')
param environmentName 'dev' | 'test' | 'prod'

@description('Primary Azure region.')
param primaryLocation string = 'westeurope'

@description('Secondary Azure region used for disaster recovery.')
param secondaryLocation string = 'swedencentral'

@description('Azure regions permitted by the location governance policy.')
param allowedLocations array = [
  primaryLocation
  secondaryLocation
]

@description('Tag names required on supported Azure resources.')
param requiredTagNames array = [
  'project'
  'environment'
  'managedBy'
  'owner'
  'costCenter'
  'criticality'
  'dataClassification'
]

@description('Controls whether governance policies audit resources or are disabled.')
@allowed([
  'Audit'
  'Disabled'
])
param policyAuditEffect string = 'Audit'

@description('Readable project name used in governance tags.')
param projectName string = 'Nordic Shopping Cloud Transformation'

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
  project: 'nordic-shopping-cloud-transformation'
  environment: environmentName
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
param storagePublicNetworkAccess string = 'Enabled'

@description('Deleted blob and container retention period.')
@minValue(1)
@maxValue(365)
param storageSoftDeleteRetentionDays int = 7

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
param sqlDatabaseSkuName string = 'GP_S_Gen5_1'
param sqlDatabaseSkuCapacity int = 1
param sqlDatabaseMaxSizeBytes int = 34359738368
param sqlDatabaseBackupRetentionDays int = 7
param sqlDatabaseBackupStorageRedundancy string = 'Local'

param appServicePlanSkuName string = 'P1v3'
@minValue(1)
param appServicePlanWorkerCount int = 2
param appServicePlanZoneRedundant bool = false

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

@description('Controls access through the public AI Services endpoint.')
@allowed([
  'Enabled'
  'Disabled'
])
param aiServicesPublicNetworkAccess string = 'Enabled'

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
var primaryKeyVaultName = 'kv-${projectCode}-${environmentName}-weu'
var secondaryKeyVaultName = 'kv-${projectCode}-${environmentName}-swc'

// Azure AI Services account names must be globally unique.
var aiServicesAccountName = 'oai-${projectCode}-${environmentName}-${take(uniqueString(subscription().id, primaryLocation), 6)}'

// Storage account names must be globally unique and contain only lowercase letters and numbers.
var primaryStorageAccountName = 'st${take(projectCode, 5)}${environmentName}${uniqueString(subscription().id, primaryLocation)}'
var secondaryStorageAccountName = 'st${take(projectCode, 5)}${environmentName}${uniqueString(subscription().id, secondaryLocation)}'

var storageContainerNames = [
  'uploads'
  'assets'
  'app-data'
  'logs'
  'backups'
]

// SQL logical server names must be globally unique.
var primarySqlServerName = 'sql-${projectCode}-${environmentName}-weu-${take(uniqueString(subscription().id, primaryLocation), 6)}'
var secondarySqlServerName = 'sql-${projectCode}-${environmentName}-swc-${take(uniqueString(subscription().id, secondaryLocation), 6)}'

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
    projectName: projectName
    projectCode: projectCode
    primaryLocation: primaryLocation
    secondaryLocation: secondaryLocation
    owner: owner
    costCenter: costCenter
    criticality: criticality
    dataClassification: dataClassification
  }
}
module wafPolicyModule './modules/security/waf-policy.bicep' = {
  name: 'deploy-waf-policy-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-global')
  params: {
    wafPolicyName: 'waf-${projectCode}-${environmentName}'
    environmentName: environmentName
    apiRateLimitThreshold: wafApiRateLimitThreshold
    authenticationRateLimitThreshold: wafAuthenticationRateLimitThreshold
    tags: tags
  }
  dependsOn: [
    resourceGroupsModule
  ]
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

module primaryStorageModule './modules/data/storage-account.bicep' = {
  name: 'deploy-primary-storage-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-weu')
  params: {
    location: primaryLocation
    storageAccountName: primaryStorageAccountName
    skuName: storageSkuName
    publicNetworkAccess: storagePublicNetworkAccess
    softDeleteRetentionDays: storageSoftDeleteRetentionDays
    oldVersionRetentionDays: storageOldVersionRetentionDays
    enableVersioning: true
    enableDiagnostics: enableStorageDiagnostics
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.workspaceId
    containerNames: storageContainerNames
    tags: tags
  }
  dependsOn: [
    resourceGroupsModule
  ]
}

module secondaryStorageModule './modules/data/storage-account.bicep' = {
  name: 'deploy-secondary-storage-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-swc')
  params: {
    location: secondaryLocation
    storageAccountName: secondaryStorageAccountName
    skuName: storageSkuName
    publicNetworkAccess: storagePublicNetworkAccess
    softDeleteRetentionDays: storageSoftDeleteRetentionDays
    oldVersionRetentionDays: storageOldVersionRetentionDays
    enableVersioning: true
    enableDiagnostics: enableStorageDiagnostics
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.workspaceId
    containerNames: storageContainerNames
    tags: tags
  }
  dependsOn: [
    resourceGroupsModule
  ]
}
module primarySqlServerModule './modules/data/sql-server.bicep' = {
  name: 'deploy-primary-sql-server-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-weu')
  params: {
    location: primaryLocation
    serverName: primarySqlServerName
    entraAdminLogin: sqlEntraAdminLogin
    entraAdminObjectId: sqlEntraAdminObjectId
    entraAdminTenantId: sqlEntraAdminTenantId
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.workspaceId
    publicNetworkAccess: environmentName == 'prod' ? 'Disabled' : 'Enabled'
    enableAdvancedThreatProtection: environmentName == 'prod'
    tags: tags
  }
  dependsOn: [
    resourceGroupsModule
  ]
}

module sqlFailoverGroupModule './modules/data/sql-failover-group.bicep' = {
  name: 'deploy-sql-failover-group-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-weu')
  params: {
    failoverGroupName: sqlFailoverGroupName
    primaryServerName: primarySqlServerModule.outputs.sqlServerName
    primaryDatabaseId: primarySqlDatabaseModule.outputs.databaseId
    secondaryServerId: secondarySqlServerModule.outputs.sqlServerId
    failoverGracePeriodMinutes: 60
    tags: tags
  }
}
module secondarySqlServerModule './modules/data/sql-server.bicep' = {
  name: 'deploy-secondary-sql-server-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-swc')
  params: {
    location: secondaryLocation
    serverName: secondarySqlServerName
    entraAdminLogin: sqlEntraAdminLogin
    entraAdminObjectId: sqlEntraAdminObjectId
    entraAdminTenantId: sqlEntraAdminTenantId
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.workspaceId
    publicNetworkAccess: environmentName == 'prod' ? 'Disabled' : 'Enabled'
    enableAdvancedThreatProtection: environmentName == 'prod'
    tags: tags
  }
  dependsOn: [
    resourceGroupsModule
  ]
}

module primarySqlDatabaseModule './modules/data/sql-database.bicep' = {
  name: 'deploy-primary-sql-database-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-weu')
  params: {
    location: primaryLocation
    serverName: primarySqlServerModule.outputs.sqlServerName
    databaseName: sqlDatabaseName
    skuName: sqlDatabaseSkuName
    skuFamily: 'Gen5'
    skuCapacity: sqlDatabaseSkuCapacity
    maxSizeBytes: sqlDatabaseMaxSizeBytes
    backupStorageRedundancy: sqlDatabaseBackupStorageRedundancy
    shortTermRetentionDays: sqlDatabaseBackupRetentionDays
    zoneRedundant: false
    tags: tags
  }
}
module primaryKeyVaultModule './modules/security/key-vault.bicep' = {
  name: 'deploy-primary-key-vault-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-weu')
  params: {
    location: primaryLocation
    keyVaultName: primaryKeyVaultName
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.workspaceId
    publicNetworkAccess: environmentName == 'prod' ? 'Disabled' : 'Enabled'
    enablePurgeProtection: enableKeyVaultPurgeProtection
    softDeleteRetentionInDays: environmentName == 'prod' ? 90 : 7
    tags: tags
  }
  dependsOn: [
    resourceGroupsModule
  ]
}
module secondaryKeyVaultModule './modules/security/key-vault.bicep' = {
  name: 'deploy-secondary-key-vault-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-swc')
  params: {
    location: secondaryLocation
    keyVaultName: secondaryKeyVaultName
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.workspaceId
    publicNetworkAccess: environmentName == 'prod' ? 'Disabled' : 'Enabled'
    enablePurgeProtection: enableKeyVaultPurgeProtection
    softDeleteRetentionInDays: environmentName == 'prod' ? 90 : 7
    tags: tags
  }
  dependsOn: [
    resourceGroupsModule
  ]
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

module primaryNetworkSecurityGroupsModule './modules/networking/network-security-groups.bicep' = {
  name: 'deploy-network-security-groups-${environmentName}-weu'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-network')
  params: {
    environmentName: environmentName
    projectCode: projectCode
    regionCode: 'weu'
    location: primaryLocation
    appIntegrationSubnetPrefix: primaryAppSubnetPrefix
    privateEndpointSubnetPrefix: primaryPrivateEndpointSubnetPrefix
    tags: tags
  }
  dependsOn: [
    resourceGroupsModule
  ]
}

module secondaryNetworkSecurityGroupsModule './modules/networking/network-security-groups.bicep' = {
  name: 'deploy-network-security-groups-${environmentName}-swc'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-network')
  params: {
    environmentName: environmentName
    projectCode: projectCode
    regionCode: 'swc'
    location: secondaryLocation
    appIntegrationSubnetPrefix: secondaryAppSubnetPrefix
    privateEndpointSubnetPrefix: secondaryPrivateEndpointSubnetPrefix
    tags: tags
  }
  dependsOn: [
    resourceGroupsModule
  ]
}
module primaryVirtualNetworkModule './modules/networking/virtual-network.bicep' = {
  name: 'deploy-virtual-network-${environmentName}-weu'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-network')
  params: {
    location: primaryLocation
    virtualNetworkName: 'vnet-${projectCode}-${environmentName}-weu'
    virtualNetworkAddressPrefix: primaryVnetAddressPrefix
    appServiceSubnetName: 'snet-app-integration'
    appServiceSubnetAddressPrefix: primaryAppSubnetPrefix
    appServiceNetworkSecurityGroupId: primaryNetworkSecurityGroupsModule.outputs.appServiceNsgId
    privateEndpointSubnetName: 'snet-private-endpoints'
    privateEndpointSubnetAddressPrefix: primaryPrivateEndpointSubnetPrefix
    privateEndpointNetworkSecurityGroupId: primaryNetworkSecurityGroupsModule.outputs.privateEndpointNsgId
    tags: tags
  }
}

module secondaryVirtualNetworkModule './modules/networking/virtual-network.bicep' = {
  name: 'deploy-virtual-network-${environmentName}-swc'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-network')
  params: {
    location: secondaryLocation
    virtualNetworkName: 'vnet-${projectCode}-${environmentName}-swc'
    virtualNetworkAddressPrefix: secondaryVnetAddressPrefix
    appServiceSubnetName: 'snet-app-integration'
    appServiceSubnetAddressPrefix: secondaryAppSubnetPrefix
    appServiceNetworkSecurityGroupId: secondaryNetworkSecurityGroupsModule.outputs.appServiceNsgId
    privateEndpointSubnetName: 'snet-private-endpoints'
    privateEndpointSubnetAddressPrefix: secondaryPrivateEndpointSubnetPrefix
    privateEndpointNetworkSecurityGroupId: secondaryNetworkSecurityGroupsModule.outputs.privateEndpointNsgId
    tags: tags
  }
}
module privateDnsZonesModule './modules/networking/private-dns-zones.bicep' = {
  name: 'deploy-private-dns-zones-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-network')
  params: {
    primaryVirtualNetworkId: primaryVirtualNetworkModule.outputs.virtualNetworkId
    secondaryVirtualNetworkId: secondaryVirtualNetworkModule.outputs.virtualNetworkId
    tags: tags
  }
}
module aiServicesAccountModule './modules/ai/ai-services-account.bicep' = {
  name: 'deploy-ai-services-account-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-weu')
  params: {
    location: primaryLocation
    accountName: aiServicesAccountName
    publicNetworkAccess: aiServicesPublicNetworkAccess
    enableDiagnostics: enableAiServicesDiagnostics
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.workspaceId
    tags: union(tags, {
      workload: 'ai-assistant'
      criticality: 'non-critical'
    })
  }
  dependsOn: [
    resourceGroupsModule
  ]
}

module aiModelDeploymentModule './modules/ai/ai-model-deployment.bicep' = {
  name: 'deploy-ai-model-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-weu')
  params: {
    aiServicesAccountName: aiServicesAccountModule.outputs.accountName
    deploymentName: aiModelDeploymentName
    modelName: aiModelName
    modelVersion: aiModelVersion
    skuName: aiModelDeploymentSkuName
    capacity: aiModelDeploymentCapacity
    enableModelDeployment: enableAiModelDeployment
  }
}
module primaryPrivateEndpointSetModule './modules/networking/private-endpoint-set.bicep' = {
  name: 'deploy-private-endpoint-set-${environmentName}-weu'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-network')
  params: {
    environmentName: environmentName
    projectCode: projectCode
    regionCode: 'weu'
    location: primaryLocation

    privateEndpointSubnetId: primaryVirtualNetworkModule.outputs.privateEndpointSubnetId

    storageAccountId: primaryStorageModule.outputs.storageAccountId
    keyVaultId: primaryKeyVaultModule.outputs.keyVaultId
    sqlServerId: primarySqlServerModule.outputs.sqlServerId

    blobPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.blob
    keyVaultPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.keyVault
    sqlPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.sql

    enableAzureOpenAIPrivateEndpoint: aiServicesPublicNetworkAccess == 'Disabled'
    azureOpenAIAccountId: aiServicesAccountModule.outputs.accountId
    azureOpenAIPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.azureOpenAI
    tags: tags
  }
}
module secondaryPrivateEndpointSetModule './modules/networking/private-endpoint-set.bicep' = {
  name: 'deploy-private-endpoint-set-${environmentName}-swc'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-network')
  params: {
    environmentName: environmentName
    projectCode: projectCode
    regionCode: 'swc'
    location: secondaryLocation

    privateEndpointSubnetId: secondaryVirtualNetworkModule.outputs.privateEndpointSubnetId

    storageAccountId: secondaryStorageModule.outputs.storageAccountId
    keyVaultId: secondaryKeyVaultModule.outputs.keyVaultId
    sqlServerId: secondarySqlServerModule.outputs.sqlServerId

    blobPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.blob
    keyVaultPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.keyVault
    sqlPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.sql

    enableAzureOpenAIPrivateEndpoint: false
    //enableAzureOpenAIPrivateEndpoint: true
    //azureOpenAIAccountId: azureOpenAIModule.outputs.accountId
    //azureOpenAIPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.azureOpenAI
    tags: tags
  }
}

module primaryAppServicePlanModule './modules/compute/app-service-plan.bicep' = {
  name: 'deploy-app-service-plan-${environmentName}-weu'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-weu')
  params: {
    location: primaryLocation
    appServicePlanName: 'asp-${projectCode}-${environmentName}-weu'
    skuName: appServicePlanSkuName
    workerCount: appServicePlanWorkerCount
    zoneRedundant: appServicePlanZoneRedundant
    tags: tags
  }
  dependsOn: [
    resourceGroupsModule
  ]
}

module secondaryAppServicePlanModule './modules/compute/app-service-plan.bicep' = {
  name: 'deploy-app-service-plan-${environmentName}-swc'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-swc')
  params: {
    location: secondaryLocation
    appServicePlanName: 'asp-${projectCode}-${environmentName}-swc'
    skuName: appServicePlanSkuName
    workerCount: appServicePlanWorkerCount
    zoneRedundant: appServicePlanZoneRedundant
    tags: tags
  }
  dependsOn: [
    resourceGroupsModule
  ]
}
module primaryAutoscaleModule './modules/compute/autoscale.bicep' = {
  name: 'deploy-autoscale-${environmentName}-weu'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-weu')
  params: {
    location: primaryLocation
    autoscaleSettingName: 'autoscale-${projectCode}-${environmentName}-weu'
    appServicePlanId: primaryAppServicePlanModule.outputs.appServicePlanId
    autoscaleEnabled: autoscaleEnabled
    minimumCapacity: primaryAutoscaleMinimumCapacity
    defaultCapacity: primaryAutoscaleDefaultCapacity
    maximumCapacity: primaryAutoscaleMaximumCapacity
  }
}
module secondaryAutoscaleModule './modules/compute/autoscale.bicep' = {
  name: 'deploy-autoscale-${environmentName}-swc'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-swc')
  params: {
    location: secondaryLocation
    autoscaleSettingName: 'autoscale-${projectCode}-${environmentName}-swc'
    appServicePlanId: secondaryAppServicePlanModule.outputs.appServicePlanId
    autoscaleEnabled: autoscaleEnabled
    minimumCapacity: secondaryAutoscaleMinimumCapacity
    defaultCapacity: secondaryAutoscaleDefaultCapacity
    maximumCapacity: secondaryAutoscaleMaximumCapacity
  }
}
module primaryWebAppModules './modules/compute/web-app.bicep' = [
  for workload in webAppWorkloads: {
    name: 'deploy-${workload.name}-web-app-${environmentName}-weu'
    scope: resourceGroup('rg-${projectCode}-${environmentName}-weu')
    params: {
      location: primaryLocation
      webAppName: 'app-${projectCode}-${environmentName}-${workload.name}-weu-${take(uniqueString(subscription().id, environmentName, workload.name, primaryLocation), 5)}'
      appServicePlanId: primaryAppServicePlanModule.outputs.appServicePlanId
      appServiceSubnetId: primaryVirtualNetworkModule.outputs.appServiceSubnetId
      logAnalyticsWorkspaceId: logAnalyticsModule.outputs.workspaceId
      applicationInsightsConnectionString: applicationInsightsModule.outputs.connectionString
      linuxRuntime: 'NODE|20-lts'
      healthCheckPath: '/health/ready'
      createStagingSlot: workload.createStagingSlot
      appSettings: {
        APP_ROLE: workload.name
        DEPLOYMENT_REGION: 'primary'
        ENVIRONMENT_NAME: environmentName
      }
      tags: union(tags, {
        workload: workload.name
        regionRole: 'primary'
      })
    }
  }
]

module secondaryWebAppModules './modules/compute/web-app.bicep' = [
  for workload in webAppWorkloads: {
    name: 'deploy-${workload.name}-web-app-${environmentName}-swc'
    scope: resourceGroup('rg-${projectCode}-${environmentName}-swc')
    params: {
      location: secondaryLocation
      webAppName: 'app-${projectCode}-${environmentName}-${workload.name}-swc-${take(uniqueString(subscription().id, environmentName, workload.name, secondaryLocation), 5)}'
      appServicePlanId: secondaryAppServicePlanModule.outputs.appServicePlanId
      appServiceSubnetId: secondaryVirtualNetworkModule.outputs.appServiceSubnetId
      logAnalyticsWorkspaceId: logAnalyticsModule.outputs.workspaceId
      applicationInsightsConnectionString: applicationInsightsModule.outputs.connectionString
      linuxRuntime: 'NODE|20-lts'
      healthCheckPath: '/health/ready'
      createStagingSlot: false
      appSettings: {
        APP_ROLE: workload.name
        DEPLOYMENT_REGION: 'secondary'
        ENVIRONMENT_NAME: environmentName
      }
      tags: union(tags, {
        workload: workload.name
        regionRole: 'secondary'
      })
    }
  }
]

module frontDoorModule './modules/networking/front-door.bicep' = {
  name: 'deploy-front-door-${environmentName}'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-global')
  params: {
    frontDoorProfileName: 'afd-${projectCode}-${environmentName}'
    endpointNamePrefix: 'afd-${projectCode}-${environmentName}-${take(uniqueString(subscription().id), 6)}'
    workloads: [
      {
        name: 'web'
        primaryHostName: primaryWebAppModules[0].outputs.webAppHostname
        secondaryHostName: secondaryWebAppModules[0].outputs.webAppHostname
      }
      {
        name: 'vendor'
        primaryHostName: primaryWebAppModules[1].outputs.webAppHostname
        secondaryHostName: secondaryWebAppModules[1].outputs.webAppHostname
      }
      {
        name: 'admin'
        primaryHostName: primaryWebAppModules[2].outputs.webAppHostname
        secondaryHostName: secondaryWebAppModules[2].outputs.webAppHostname
      }
      {
        name: 'api'
        primaryHostName: primaryWebAppModules[3].outputs.webAppHostname
        secondaryHostName: secondaryWebAppModules[3].outputs.webAppHostname
      }
    ]
    wafPolicyId: wafPolicyModule.outputs.wafPolicyId
    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.workspaceId
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
    frontDoorProfileId: frontDoorModule.outputs.frontDoorProfileId

    appServicePlanIds: [
      primaryAppServicePlanModule.outputs.appServicePlanId
      secondaryAppServicePlanModule.outputs.appServicePlanId
    ]

    webAppIds: [
      primaryWebAppModules[0].outputs.webAppId
      primaryWebAppModules[1].outputs.webAppId
      primaryWebAppModules[2].outputs.webAppId
      primaryWebAppModules[3].outputs.webAppId

      secondaryWebAppModules[0].outputs.webAppId
      secondaryWebAppModules[1].outputs.webAppId
      secondaryWebAppModules[2].outputs.webAppId
      secondaryWebAppModules[3].outputs.webAppId
    ]

    sqlDatabaseIds: [
      primarySqlDatabaseModule.outputs.databaseId
      resourceId(
        'rg-${projectCode}-${environmentName}-swc',
        'Microsoft.Sql/servers/databases',
        secondarySqlServerModule.outputs.sqlServerName,
        sqlDatabaseName
      )
    ]

    storageAccountIds: [
      primaryStorageModule.outputs.storageAccountId
      secondaryStorageModule.outputs.storageAccountId
    ]

    keyVaultIds: [
      primaryKeyVaultModule.outputs.keyVaultId
      secondaryKeyVaultModule.outputs.keyVaultId
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
module primaryOriginLockdownModule './modules/compute/app-service-origin-lockdown.bicep' = {
  name: 'deploy-origin-lockdown-${environmentName}-weu'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-weu')
  params: {
    webAppNames: [for (workload, index) in webAppWorkloads: primaryWebAppModules[index].outputs.webAppName]
    frontDoorId: frontDoorModule.outputs.frontDoorId
  }
}

module secondaryOriginLockdownModule './modules/compute/app-service-origin-lockdown.bicep' = {
  name: 'deploy-origin-lockdown-${environmentName}-swc'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-swc')
  params: {
    webAppNames: [for (workload, index) in webAppWorkloads: secondaryWebAppModules[index].outputs.webAppName]
    frontDoorId: frontDoorModule.outputs.frontDoorId
  }
}
module primaryWorkloadRbacModule './modules/identity/workload-rbac.bicep' = {
  name: 'deploy-workload-rbac-${environmentName}-weu'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-weu')
  params: {
    apiPrincipalId: primaryWebAppModules[3].outputs.webAppPrincipalId
    enableApiDataAccess: true
    storageAccountName: primaryStorageModule.outputs.storageAccountName
    blobContainerNames: [
      'uploads'
      'assets'
      'app-data'
    ]
    keyVaultName: primaryKeyVaultModule.outputs.keyVaultName

    automationPrincipalId: managedIdentitiesModule.outputs.automationIdentityPrincipalId
    enableAutomationAccess: true
    webAppNames: [for (workload, index) in webAppWorkloads: primaryWebAppModules[index].outputs.webAppName]

    aiOperationsPrincipalId: managedIdentitiesModule.outputs.aiOperationsIdentityPrincipalId
    enableAiAccess: enableAiOperationsIdentity
    aiServicesAccountName: aiServicesAccountModule.outputs.accountName
  }
}

module secondaryWorkloadRbacModule './modules/identity/workload-rbac.bicep' = {
  name: 'deploy-workload-rbac-${environmentName}-swc'
  scope: resourceGroup('rg-${projectCode}-${environmentName}-swc')
  params: {
    apiPrincipalId: secondaryWebAppModules[3].outputs.webAppPrincipalId
    enableApiDataAccess: true
    storageAccountName: secondaryStorageModule.outputs.storageAccountName
    blobContainerNames: [
      'uploads'
      'assets'
      'app-data'
    ]
    keyVaultName: secondaryKeyVaultModule.outputs.keyVaultName

    automationPrincipalId: managedIdentitiesModule.outputs.automationIdentityPrincipalId
    enableAutomationAccess: true
    webAppNames: [for (workload, index) in webAppWorkloads: secondaryWebAppModules[index].outputs.webAppName]
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
      'rg-${projectCode}-${environmentName}-weu'
      'rg-${projectCode}-${environmentName}-swc'
      'rg-${projectCode}-${environmentName}-network'
      'rg-${projectCode}-${environmentName}-monitor'
      'rg-${projectCode}-${environmentName}-security'
    ]

    operationsResourceGroupNames: [
      'rg-${projectCode}-${environmentName}-global'
      'rg-${projectCode}-${environmentName}-weu'
      'rg-${projectCode}-${environmentName}-swc'
      'rg-${projectCode}-${environmentName}-monitor'
    ]

    primaryResourceGroupName: 'rg-${projectCode}-${environmentName}-weu'
    secondaryResourceGroupName: 'rg-${projectCode}-${environmentName}-swc'
    monitoringResourceGroupName: 'rg-${projectCode}-${environmentName}-monitor'

    primaryWebAppNames: [for (workload, index) in webAppWorkloads: primaryWebAppModules[index].outputs.webAppName]

    secondaryWebAppNames: [for (workload, index) in webAppWorkloads: secondaryWebAppModules[index].outputs.webAppName]

    primarySqlServerName: primarySqlServerModule.outputs.sqlServerName
    secondarySqlServerName: secondarySqlServerModule.outputs.sqlServerName
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
    budgetName: 'budget-${projectCode}-monthly'
    budgetAmount: budgetAmount
    startDate: budgetStartDate
    endDate: budgetEndDate
    contactEmail: budgetContactEmail
    actionGroupIds: union(budgetActionGroupIds, [
      actionGroupsModule.outputs.costActionGroupId
    ])
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
output primaryAppServiceNsgId string = primaryNetworkSecurityGroupsModule.outputs.appServiceNsgId
output primaryPrivateEndpointNsgId string = primaryNetworkSecurityGroupsModule.outputs.privateEndpointNsgId
output secondaryAppServiceNsgId string = secondaryNetworkSecurityGroupsModule.outputs.appServiceNsgId
output secondaryPrivateEndpointNsgId string = secondaryNetworkSecurityGroupsModule.outputs.privateEndpointNsgId

//VNET outputs
output primaryVirtualNetworkId string = primaryVirtualNetworkModule.outputs.virtualNetworkId
output primaryAppServiceSubnetId string = primaryVirtualNetworkModule.outputs.appServiceSubnetId
output primaryPrivateEndpointSubnetId string = primaryVirtualNetworkModule.outputs.privateEndpointSubnetId

output secondaryVirtualNetworkId string = secondaryVirtualNetworkModule.outputs.virtualNetworkId
output secondaryAppServiceSubnetId string = secondaryVirtualNetworkModule.outputs.appServiceSubnetId
output secondaryPrivateEndpointSubnetId string = secondaryVirtualNetworkModule.outputs.privateEndpointSubnetId

// Managed identity outputs
output automationIdentityResourceId string = managedIdentitiesModule.outputs.automationIdentityResourceId
output automationIdentityPrincipalId string = managedIdentitiesModule.outputs.automationIdentityPrincipalId
output automationIdentityClientId string = managedIdentitiesModule.outputs.automationIdentityClientId

output aiOperationsIdentityResourceId string = managedIdentitiesModule.outputs.aiOperationsIdentityResourceId
output aiOperationsIdentityPrincipalId string = managedIdentitiesModule.outputs.aiOperationsIdentityPrincipalId
output aiOperationsIdentityClientId string = managedIdentitiesModule.outputs.aiOperationsIdentityClientId

//Storage accounts output
output primaryStorageAccountId string = primaryStorageModule.outputs.storageAccountId
output primaryStorageAccountName string = primaryStorageModule.outputs.storageAccountName
output primaryBlobEndpoint string = primaryStorageModule.outputs.blobEndpoint

output secondaryStorageAccountId string = secondaryStorageModule.outputs.storageAccountId
output secondaryStorageAccountName string = secondaryStorageModule.outputs.storageAccountName
output secondaryBlobEndpoint string = secondaryStorageModule.outputs.blobEndpoint

// SQL logical server outputs
output primarySqlServerId string = primarySqlServerModule.outputs.sqlServerId
output primarySqlServerName string = primarySqlServerModule.outputs.sqlServerName
output primarySqlServerFullyQualifiedDomainName string = primarySqlServerModule.outputs.fullyQualifiedDomainName

output secondarySqlServerId string = secondarySqlServerModule.outputs.sqlServerId
output secondarySqlServerName string = secondarySqlServerModule.outputs.sqlServerName
output secondarySqlServerFullyQualifiedDomainName string = secondarySqlServerModule.outputs.fullyQualifiedDomainName
// SQL database outputs
output primarySqlDatabaseId string = primarySqlDatabaseModule.outputs.databaseId
output primarySqlDatabaseName string = primarySqlDatabaseModule.outputs.databaseName

// Key Vault outputs
output primaryKeyVaultId string = primaryKeyVaultModule.outputs.keyVaultId
output primaryKeyVaultName string = primaryKeyVaultModule.outputs.keyVaultName
output secondaryKeyVaultId string = secondaryKeyVaultModule.outputs.keyVaultId
output secondaryKeyVaultName string = secondaryKeyVaultModule.outputs.keyVaultName

//app service plan outputs
output primaryAppServicePlanId string = primaryAppServicePlanModule.outputs.appServicePlanId
output primaryAppServicePlanName string = primaryAppServicePlanModule.outputs.appServicePlanName
output primaryAppServiceLocation string = primaryAppServicePlanModule.outputs.appServicePlanLocation

output secondaryAppServicePlanId string = secondaryAppServicePlanModule.outputs.appServicePlanId
output secondaryAppServicePlanName string = secondaryAppServicePlanModule.outputs.appServicePlanName
output secondaryAppServiceLocation string = secondaryAppServicePlanModule.outputs.appServicePlanLocation

// Web App outputs
output primaryWebApps array = [
  for (workload, index) in webAppWorkloads: {
    workload: workload.name
    webAppId: primaryWebAppModules[index].outputs.webAppId
    webAppName: primaryWebAppModules[index].outputs.webAppName
    hostname: primaryWebAppModules[index].outputs.webAppHostname
    principalId: primaryWebAppModules[index].outputs.webAppPrincipalId
    stagingSlotName: primaryWebAppModules[index].outputs.stagingSlotName
  }
]

output secondaryWebApps array = [
  for (workload, index) in webAppWorkloads: {
    workload: workload.name
    webAppId: secondaryWebAppModules[index].outputs.webAppId
    webAppName: secondaryWebAppModules[index].outputs.webAppName
    hostname: secondaryWebAppModules[index].outputs.webAppHostname
    principalId: secondaryWebAppModules[index].outputs.webAppPrincipalId
  }
]
// AI Services outputs
output aiServicesAccountId string = aiServicesAccountModule.outputs.accountId
output aiServicesAccountName string = aiServicesAccountModule.outputs.accountName
output aiServicesEndpoint string = aiServicesAccountModule.outputs.endpoint
output aiServicesPrincipalId string = aiServicesAccountModule.outputs.principalId

// WAF policy outputs
//output wafPolicyId string = wafPolicyModule.outputs.wafPolicyId
//output wafPolicyName string = wafPolicyModule.outputs.wafPolicyName
//output wafMode string = wafPolicyModule.outputs.wafMode

/*output frontDoorProfileId string = frontDoorModule.outputs.frontDoorProfileId
output frontDoorProfileName string = frontDoorModule.outputs.frontDoorProfileName
output frontDoorId string = frontDoorModule.outputs.frontDoorId
output frontDoorEndpoints array = frontDoorModule.outputs.endpointDetails

output wafPolicyId string = wafPolicyModule.outputs.wafPolicyId
output wafPolicyName string = wafPolicyModule.outputs.wafPolicyName*/
