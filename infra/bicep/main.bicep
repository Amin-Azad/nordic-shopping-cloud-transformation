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
