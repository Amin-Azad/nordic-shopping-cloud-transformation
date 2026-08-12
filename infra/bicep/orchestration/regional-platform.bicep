targetScope = 'resourceGroup'

@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string

@allowed([
  'primary'
  'secondary'
])
param regionRole string

param projectCode string = 'nshop'
param regionCode string
param location string
param networkResourceGroupName string

param virtualNetworkAddressPrefix string
param appServiceSubnetAddressPrefix string
param privateEndpointSubnetAddressPrefix string

param storageAccountName string
param storageSkuName string
param storagePublicNetworkAccess string
param storageSoftDeleteRetentionDays int
param storageOldVersionRetentionDays int
param enableStorageDiagnostics bool
param storageContainerNames array

param keyVaultName string
param enableKeyVaultPurgeProtection bool

param sqlServerName string
param sqlEntraAdminLogin string
param sqlEntraAdminObjectId string
param sqlEntraAdminTenantId string
param sqlDatabaseName string
param sqlDatabaseSkuName string
param sqlDatabaseSkuCapacity int
param sqlDatabaseMaxSizeBytes int
param sqlDatabaseBackupRetentionDays int
param sqlDatabaseBackupStorageRedundancy string

param appServicePlanSkuName string
param appServicePlanWorkerCount int
param appServicePlanZoneRedundant bool
param autoscaleEnabled bool
param autoscaleMinimumCapacity int
param autoscaleDefaultCapacity int
param autoscaleMaximumCapacity int
param workloads array

param logAnalyticsWorkspaceId string
param applicationInsightsConnectionString string

param blobPrivateDnsZoneId string
param keyVaultPrivateDnsZoneId string
param sqlPrivateDnsZoneId string
param azureOpenAIPrivateDnsZoneId string = ''

param deployAiServices bool = false
param aiServicesAccountName string = ''
param aiServicesPublicNetworkAccess string = 'Enabled'
param enableAiServicesDiagnostics bool = true
param enableAiModelDeployment bool = false
param aiModelDeploymentName string = 'gpt-4o-mini'
param aiModelName string = 'gpt-4o-mini'
param aiModelVersion string = '2024-07-18'
param aiModelDeploymentSkuName string = 'Standard'
param aiModelDeploymentCapacity int = 1

param tags object

var isPrimaryRegion = regionRole == 'primary'
var publicNetworkAccess = environmentName == 'prod' ? 'Disabled' : 'Enabled'

module networkSecurityGroupsModule '../modules/networking/network-security-groups.bicep' = {
  name: 'deploy-network-security-groups-${environmentName}-${regionCode}'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    environmentName: environmentName
    projectCode: projectCode
    regionCode: regionCode
    location: location
    appIntegrationSubnetPrefix: appServiceSubnetAddressPrefix
    privateEndpointSubnetPrefix: privateEndpointSubnetAddressPrefix
    tags: tags
  }
}

module virtualNetworkModule '../modules/networking/virtual-network.bicep' = {
  name: 'deploy-virtual-network-${environmentName}-${regionCode}'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    location: location
    virtualNetworkName: 'vnet-${projectCode}-${environmentName}-${regionCode}'
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    appServiceSubnetAddressPrefix: appServiceSubnetAddressPrefix
    appServiceNetworkSecurityGroupId: networkSecurityGroupsModule.outputs.appServiceNsgId
    privateEndpointSubnetAddressPrefix: privateEndpointSubnetAddressPrefix
    privateEndpointNetworkSecurityGroupId: networkSecurityGroupsModule.outputs.privateEndpointNsgId
    tags: tags
  }
}

module storageModule '../modules/data/storage-account.bicep' = {
  name: 'deploy-storage-${environmentName}-${regionCode}'
  params: {
    location: location
    storageAccountName: storageAccountName
    skuName: storageSkuName
    publicNetworkAccess: storagePublicNetworkAccess
    softDeleteRetentionDays: storageSoftDeleteRetentionDays
    oldVersionRetentionDays: storageOldVersionRetentionDays
    enableVersioning: true
    enableDiagnostics: enableStorageDiagnostics
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    containerNames: storageContainerNames
    tags: tags
  }
}

module keyVaultModule '../modules/security/key-vault.bicep' = {
  name: 'deploy-key-vault-${environmentName}-${regionCode}'
  params: {
    location: location
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    publicNetworkAccess: publicNetworkAccess
    enablePurgeProtection: enableKeyVaultPurgeProtection
    softDeleteRetentionInDays: environmentName == 'prod' ? 90 : 7
    tags: tags
  }
}

module sqlServerModule '../modules/data/sql-server.bicep' = {
  name: 'deploy-sql-server-${environmentName}-${regionCode}'
  params: {
    location: location
    serverName: sqlServerName
    entraAdminLogin: sqlEntraAdminLogin
    entraAdminObjectId: sqlEntraAdminObjectId
    entraAdminTenantId: sqlEntraAdminTenantId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    publicNetworkAccess: publicNetworkAccess
    enableAdvancedThreatProtection: environmentName == 'prod'
    tags: tags
  }
}

module sqlDatabaseModule '../modules/data/sql-database.bicep' = if (isPrimaryRegion) {
  name: 'deploy-sql-database-${environmentName}-${regionCode}'
  params: {
    location: location
    serverName: sqlServerModule.outputs.sqlServerName
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

module aiServicesAccountModule '../modules/ai/ai-services-account.bicep' = if (deployAiServices) {
  name: 'deploy-ai-services-account-${environmentName}-${regionCode}'
  params: {
    location: location
    accountName: aiServicesAccountName
    publicNetworkAccess: aiServicesPublicNetworkAccess
    enableDiagnostics: enableAiServicesDiagnostics
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    tags: union(tags, {
      workload: 'ai-assistant'
      criticality: 'non-critical'
    })
  }
}

module aiModelDeploymentModule '../modules/ai/ai-model-deployment.bicep' = if (deployAiServices) {
  name: 'deploy-ai-model-${environmentName}-${regionCode}'
  params: {
    aiServicesAccountName: aiServicesAccountModule!.outputs.accountName
    deploymentName: aiModelDeploymentName
    modelName: aiModelName
    modelVersion: aiModelVersion
    skuName: aiModelDeploymentSkuName
    capacity: aiModelDeploymentCapacity
    enableModelDeployment: enableAiModelDeployment
  }
}

module privateEndpointSetModule '../modules/networking/private-endpoint-set.bicep' = {
  name: 'deploy-private-endpoint-set-${environmentName}-${regionCode}'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    environmentName: environmentName
    projectCode: projectCode
    regionCode: regionCode
    location: location
    privateEndpointSubnetId: virtualNetworkModule.outputs.privateEndpointSubnetId
    storageAccountId: storageModule.outputs.storageAccountId
    keyVaultId: keyVaultModule.outputs.keyVaultId
    sqlServerId: sqlServerModule.outputs.sqlServerId
    blobPrivateDnsZoneId: blobPrivateDnsZoneId
    keyVaultPrivateDnsZoneId: keyVaultPrivateDnsZoneId
    sqlPrivateDnsZoneId: sqlPrivateDnsZoneId
    enableAzureOpenAIPrivateEndpoint: deployAiServices && aiServicesPublicNetworkAccess == 'Disabled'
    azureOpenAIAccountId: deployAiServices ? aiServicesAccountModule!.outputs.accountId : ''
    azureOpenAIPrivateDnsZoneId: azureOpenAIPrivateDnsZoneId
    tags: tags
  }
}

module appServicePlanModule '../modules/compute/app-service-plan.bicep' = {
  name: 'deploy-app-service-plan-${environmentName}-${regionCode}'
  params: {
    location: location
    appServicePlanName: 'asp-${projectCode}-${environmentName}-${regionCode}'
    skuName: appServicePlanSkuName
    workerCount: appServicePlanWorkerCount
    zoneRedundant: appServicePlanZoneRedundant
    tags: tags
  }
}

module autoscaleModule '../modules/compute/autoscale.bicep' = {
  name: 'deploy-autoscale-${environmentName}-${regionCode}'
  params: {
    location: location
    autoscaleSettingName: 'autoscale-${projectCode}-${environmentName}-${regionCode}'
    appServicePlanId: appServicePlanModule.outputs.appServicePlanId
    autoscaleEnabled: autoscaleEnabled
    minimumCapacity: autoscaleMinimumCapacity
    defaultCapacity: autoscaleDefaultCapacity
    maximumCapacity: autoscaleMaximumCapacity
  }
}

module webAppModules '../modules/compute/web-app.bicep' = [
  for workload in workloads: {
    name: 'deploy-${workload.name}-web-app-${environmentName}-${regionCode}'
    params: {
      location: location
      webAppName: 'app-${projectCode}-${environmentName}-${workload.name}-${regionCode}-${take(uniqueString(subscription().id, environmentName, workload.name, location), 5)}'
      appServicePlanId: appServicePlanModule.outputs.appServicePlanId
      appServiceSubnetId: virtualNetworkModule.outputs.appServiceSubnetId
      logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
      applicationInsightsConnectionString: applicationInsightsConnectionString
      linuxRuntime: 'NODE|20-lts'
      healthCheckPath: '/health/ready'
      createStagingSlot: isPrimaryRegion && workload.createStagingSlot
      appSettings: {
        APP_ROLE: workload.name
        DEPLOYMENT_REGION: regionRole
        ENVIRONMENT_NAME: environmentName
      }
      tags: union(tags, {
        workload: workload.name
        regionRole: regionRole
      })
    }
  }
]

output location string = location
output regionCode string = regionCode
output regionRole string = regionRole

output virtualNetworkId string = virtualNetworkModule.outputs.virtualNetworkId
output appServiceSubnetId string = virtualNetworkModule.outputs.appServiceSubnetId
output privateEndpointSubnetId string = virtualNetworkModule.outputs.privateEndpointSubnetId
output appServiceNsgId string = networkSecurityGroupsModule.outputs.appServiceNsgId
output privateEndpointNsgId string = networkSecurityGroupsModule.outputs.privateEndpointNsgId

output storageAccountId string = storageModule.outputs.storageAccountId
output storageAccountName string = storageModule.outputs.storageAccountName
output storageBlobEndpoint string = storageModule.outputs.blobEndpoint
output keyVaultId string = keyVaultModule.outputs.keyVaultId
output keyVaultName string = keyVaultModule.outputs.keyVaultName
output keyVaultUri string = keyVaultModule.outputs.keyVaultUri
output sqlServerId string = sqlServerModule.outputs.sqlServerId
output sqlServerName string = sqlServerModule.outputs.sqlServerName
output sqlServerFullyQualifiedDomainName string = sqlServerModule.outputs.fullyQualifiedDomainName
output sqlDatabaseId string = isPrimaryRegion ? sqlDatabaseModule!.outputs.databaseId : ''
output sqlDatabaseName string = isPrimaryRegion ? sqlDatabaseModule!.outputs.databaseName : ''

output appServicePlanId string = appServicePlanModule.outputs.appServicePlanId
output appServicePlanName string = appServicePlanModule.outputs.appServicePlanName
output autoscaleSettingId string = autoscaleModule.outputs.autoscaleSettingId
output webApps array = [
  for (workload, index) in workloads: {
    name: workload.name
    webAppId: webAppModules[index].outputs.webAppId
    webAppName: webAppModules[index].outputs.webAppName
    hostname: webAppModules[index].outputs.webAppHostname
    principalId: webAppModules[index].outputs.webAppPrincipalId
    stagingSlotName: webAppModules[index].outputs.stagingSlotName
    stagingSlotPrincipalId: webAppModules[index].outputs.stagingSlotPrincipalId
  }
]

output storageBlobPrivateEndpointId string = privateEndpointSetModule.outputs.storageBlobPrivateEndpointId
output keyVaultPrivateEndpointId string = privateEndpointSetModule.outputs.keyVaultPrivateEndpointId
output sqlPrivateEndpointId string = privateEndpointSetModule.outputs.sqlPrivateEndpointId
output azureOpenAIPrivateEndpointId string = privateEndpointSetModule.outputs.azureOpenAIPrivateEndpointId

output aiServicesAccountId string = deployAiServices ? aiServicesAccountModule!.outputs.accountId : ''
output aiServicesAccountName string = deployAiServices ? aiServicesAccountModule!.outputs.accountName : ''
output aiServicesEndpoint string = deployAiServices ? aiServicesAccountModule!.outputs.endpoint : ''
output aiServicesPrincipalId string = deployAiServices ? aiServicesAccountModule!.outputs.principalId : ''
output aiModelDeploymentId string = deployAiServices ? aiModelDeploymentModule!.outputs.deploymentId : ''
