targetScope = 'subscription'

metadata name = 'Nordic Shopping minimal profile'
metadata description = '''
Single-region subset of the Nordic Shopping architecture, sized to deploy on a
sandbox subscription. Reuses the same modules as main.bicep. Omits the secondary
region, SQL failover group, Front Door, WAF, autoscale and staging slots.
'''

// ---------------------------------------------------------------------------
// Identity of the deployment
// ---------------------------------------------------------------------------

@description('Deployment environment.')
param environmentName 'dev' | 'test' | 'prod' = 'dev'

@description('Short project code used in Azure resource names.')
@minLength(2)
@maxLength(10)
param projectCode string = 'nshop'

@description('Azure region for every resource in this profile.')
param location string

@description('Short code used in names for the Azure region, for example sdc or neu.')
@minLength(2)
@maxLength(6)
param regionCode string

@description('Team or person responsible for the environment.')
@minLength(1)
param owner string

@description('Cost centre used for Azure cost allocation.')
@minLength(1)
param costCenter string

@description('Business criticality classification.')
@allowed([
  'low'
  'medium'
  'high'
])
param criticality string = 'low'

@description('Data classification applied to resources.')
@allowed([
  'public'
  'internal'
  'confidential'
])
param dataClassification string = 'internal'

@description('Tags applied to every resource.')
param tags object

// ---------------------------------------------------------------------------
// Networking
// ---------------------------------------------------------------------------

@description('Address space of the virtual network.')
param virtualNetworkAddressPrefix string = '10.20.0.0/16'

@description('Subnet delegated to App Service regional VNet integration.')
param appServiceSubnetAddressPrefix string = '10.20.1.0/24'

@description('Subnet holding the private endpoints.')
param privateEndpointSubnetAddressPrefix string = '10.20.2.0/24'

// ---------------------------------------------------------------------------
// Workload
// ---------------------------------------------------------------------------

@description('Web applications deployed by this profile. The minimal profile deploys one.')
param webAppWorkloads array = [
  {
    name: 'api'
    createStagingSlot: false
  }
]

@description('Allows direct public ingress. Required because this profile has no Front Door.')
param allowDirectAppServiceIngress bool = true

@description('Linux App Service plan SKU. B1 is the smallest slot-free tier that supports Always On.')
param appServicePlanSkuName string = 'B1'

@description('Number of App Service plan workers.')
@minValue(1)
@maxValue(3)
param appServicePlanWorkerCount int = 1

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

param storageSkuName string = 'Standard_LRS'

@description('Storage public network access. Disabled is the point of the private endpoint.')
@allowed([
  'Enabled'
  'Disabled'
])
param storagePublicNetworkAccess string = 'Disabled'

param storageContainerNames array = [
  'product-images'
  'order-documents'
]

@description('Purge protection blocks Key Vault deletion for 90 days. Keep false for short-lived environments.')
param enableKeyVaultPurgeProtection bool = false

param sqlEntraAdminLogin string
param sqlEntraAdminObjectId string
param sqlEntraAdminTenantId string = tenant().tenantId

param sqlDatabaseName string = 'sqldb-orders'
param sqlDatabaseSkuName string = 'GP_S_Gen5_1'
param sqlDatabaseSkuCapacity int = 1
param sqlDatabaseMaxSizeBytes int = 34359738368
param sqlDatabaseBackupRetentionDays int = 7
param sqlDatabaseBackupStorageRedundancy string = 'Local'

@description('''
Serverless auto-pause delay in minutes. This profile has no failover group, so
the database may pause and bill storage only. 60 is Azure's minimum.
''')
@minValue(60)
param sqlAutoPauseDelayMinutes int = 60

// ---------------------------------------------------------------------------
// Monitoring
// ---------------------------------------------------------------------------

param logRetentionInDays int = 30
param logDailyQuotaGb int = 1

param operationalEmailReceivers array = []
param securityEmailReceivers array = []
param costEmailReceivers array = []

param enableMetricAlerts bool = true
param enableAvailabilityTest bool = true

@allowed([0, 1, 2, 3, 4])
param availabilityAlertSeverity int = 1

// ---------------------------------------------------------------------------
// Governance
// ---------------------------------------------------------------------------

@description('Azure regions permitted by the location governance policy.')
param allowedLocations array = [
  location
]

param requiredTagNames array = [
  'application'
  'environment'
  'owner'
  'costCentre'
  'dataClassification'
  'criticality'
  'managedBy'
]

@allowed([
  'Audit'
  'Disabled'
])
param policyAuditEffect string = 'Audit'

param budgetAmount int = 300
param budgetStartDate string
param budgetEndDate string
param budgetContactEmail string

// ---------------------------------------------------------------------------
// Names and scopes
// ---------------------------------------------------------------------------

var regionalResourceGroupName = 'rg-${projectCode}-${environmentName}-${regionCode}'
var networkResourceGroupName = 'rg-${projectCode}-${environmentName}-network'
var monitoringResourceGroupName = 'rg-${projectCode}-${environmentName}-monitor'

var storageAccountName = 'st${projectCode}${environmentName}${regionCode}${take(uniqueString(subscription().id, location), 6)}'
var keyVaultName = 'kv-${projectCode}-${environmentName}-${regionCode}-${take(uniqueString(subscription().id, location), 6)}'
var sqlServerName = 'sql-${projectCode}-${environmentName}-${regionCode}-${take(uniqueString(subscription().id, location), 6)}'
var applicationInsightsName = 'appi-${projectCode}-${environmentName}'
var logAnalyticsWorkspaceName = 'log-${projectCode}-${environmentName}'

var resourceGroupTags = union(tags, {
  owner: owner
  costCentre: costCenter
  criticality: criticality
  dataClassification: dataClassification
})

// ---------------------------------------------------------------------------
// Resource groups
// ---------------------------------------------------------------------------

resource regionalResourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: regionalResourceGroupName
  location: location
  tags: resourceGroupTags
}

resource networkResourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: networkResourceGroupName
  location: location
  tags: resourceGroupTags
}

resource monitoringResourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: monitoringResourceGroupName
  location: location
  tags: resourceGroupTags
}

// ---------------------------------------------------------------------------
// Monitoring foundation
// ---------------------------------------------------------------------------

module logAnalyticsModule './modules/monitoring/log-analytics.bicep' = {
  name: 'minimal-log-analytics-${environmentName}'
  scope: monitoringResourceGroup
  params: {
    location: location
    workspaceName: logAnalyticsWorkspaceName
    retentionInDays: logRetentionInDays
    dailyQuotaGb: logDailyQuotaGb
    tags: tags
  }
}

module applicationInsightsModule './modules/monitoring/application-insights.bicep' = {
  name: 'minimal-application-insights-${environmentName}'
  scope: monitoringResourceGroup
  params: {
    location: location
    applicationInsightsName: applicationInsightsName
    logAnalyticsWorkspaceResourceId: logAnalyticsModule.outputs.workspaceId
    tags: tags
  }
}

// An unset GitHub variable arrives as an empty string. Azure rejects an action
// group whose receiver has a blank emailAddress, so drop those rather than fail
// the whole deployment over a missing notification address.
var validOperationalReceivers = filter(operationalEmailReceivers, receiver => !empty(receiver.emailAddress))
var validSecurityReceivers = filter(securityEmailReceivers, receiver => !empty(receiver.emailAddress))
var validCostReceivers = filter(costEmailReceivers, receiver => !empty(receiver.emailAddress))

module actionGroupsModule './modules/monitoring/action-groups.bicep' = {
  name: 'minimal-action-groups-${environmentName}'
  scope: monitoringResourceGroup
  params: {
    environmentName: environmentName
    projectCode: projectCode
    operationalEmailReceivers: validOperationalReceivers
    securityEmailReceivers: validSecurityReceivers
    costEmailReceivers: validCostReceivers
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Private DNS
// ---------------------------------------------------------------------------

module privateDnsZonesModule './modules/networking/private-dns-zones.bicep' = {
  name: 'minimal-private-dns-zones-${environmentName}'
  scope: networkResourceGroup
  params: {
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Regional platform: network, storage, key vault, SQL, private endpoints,
// app service plan and web apps. Same module main.bicep uses.
// ---------------------------------------------------------------------------

module regionalPlatformModule './orchestration/regional-platform.bicep' = {
  name: 'minimal-regional-platform-${environmentName}-${regionCode}'
  scope: regionalResourceGroup
  params: {
    environmentName: environmentName
    regionRole: 'primary'
    projectCode: projectCode
    regionCode: regionCode
    location: location
    networkResourceGroupName: networkResourceGroupName

    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    appServiceSubnetAddressPrefix: appServiceSubnetAddressPrefix
    privateEndpointSubnetAddressPrefix: privateEndpointSubnetAddressPrefix

    storageAccountName: storageAccountName
    storageSkuName: storageSkuName
    storagePublicNetworkAccess: storagePublicNetworkAccess
    enableStorageDiagnostics: true
    storageContainerNames: storageContainerNames
    storageSoftDeleteRetentionDays: 7
    storageContainerSoftDeleteRetentionDays: 7
    storageOldVersionRetentionDays: 30

    keyVaultName: keyVaultName
    enableKeyVaultPurgeProtection: enableKeyVaultPurgeProtection
    forcePrivateKeyVault: true

    sqlServerName: sqlServerName
    sqlEntraAdminLogin: sqlEntraAdminLogin
    sqlEntraAdminObjectId: sqlEntraAdminObjectId
    sqlEntraAdminTenantId: sqlEntraAdminTenantId
    forcePrivateSql: true

    sqlDatabaseName: sqlDatabaseName
    sqlDatabaseSkuName: sqlDatabaseSkuName
    sqlDatabaseSkuCapacity: sqlDatabaseSkuCapacity
    sqlDatabaseZoneRedundant: false
    sqlDatabaseMaxSizeBytes: sqlDatabaseMaxSizeBytes
    sqlDatabaseBackupRetentionDays: sqlDatabaseBackupRetentionDays
    sqlDatabaseBackupStorageRedundancy: sqlDatabaseBackupStorageRedundancy
    sqlAutoPauseDelayMinutes: sqlAutoPauseDelayMinutes

    appServicePlanSkuName: appServicePlanSkuName
    appServicePlanWorkerCount: appServicePlanWorkerCount
    appServicePlanZoneRedundant: false
    autoscaleEnabled: false
    autoscaleMinimumCapacity: 1
    autoscaleDefaultCapacity: 1
    autoscaleMaximumCapacity: 1

    workloads: webAppWorkloads
    createAllStagingSlots: false
    allowDirectAppServiceIngress: allowDirectAppServiceIngress

    logAnalyticsWorkspaceId: logAnalyticsModule.outputs.workspaceId
    applicationInsightsConnectionString: applicationInsightsModule.outputs.connectionString

    blobPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.blob
    keyVaultPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.keyVault
    sqlPrivateDnsZoneId: privateDnsZonesModule.outputs.privateDnsZoneIds.sql

    deployAiServices: false

    tags: tags
  }
}

module privateDnsVnetLinksModule './modules/networking/private-dns-vnet-links.bicep' = {
  name: 'minimal-private-dns-vnet-links-${environmentName}'
  scope: networkResourceGroup
  params: {
    primaryVirtualNetworkId: regionalPlatformModule.outputs.virtualNetworkId
  }
}

// ---------------------------------------------------------------------------
// Workload identity access: the web app reads Key Vault and Storage through
// its system-assigned managed identity. This is what /health/ready proves.
// ---------------------------------------------------------------------------

module workloadRbacModule './modules/identity/workload-rbac.bicep' = {
  name: 'minimal-workload-rbac-${environmentName}-${regionCode}'
  scope: regionalResourceGroup
  params: {
    apiPrincipalId: regionalPlatformModule.outputs.webApps[0].principalId
    enableApiDataAccess: true
    storageAccountName: regionalPlatformModule.outputs.storageAccountName
    blobContainerNames: storageContainerNames
    keyVaultName: regionalPlatformModule.outputs.keyVaultName
  }
}

// ---------------------------------------------------------------------------
// Alerts
// ---------------------------------------------------------------------------

module metricAlertsModule './modules/monitoring/metric-alerts.bicep' = {
  name: 'minimal-metric-alerts-${environmentName}'
  scope: monitoringResourceGroup
  params: {
    environmentName: environmentName
    enableFrontDoorAlerts: false

    appServicePlanIds: [
      regionalPlatformModule.outputs.appServicePlanId
    ]
    webAppIds: regionalPlatformModule.outputs.webAppIds
    sqlDatabaseIds: [
      regionalPlatformModule.outputs.sqlDatabaseId
    ]
    storageAccountIds: [
      regionalPlatformModule.outputs.storageAccountId
    ]
    keyVaultIds: [
      regionalPlatformModule.outputs.keyVaultId
    ]

    operationalActionGroupId: actionGroupsModule.outputs.operationalActionGroupId
    securityActionGroupId: actionGroupsModule.outputs.securityActionGroupId
    enabled: enableMetricAlerts
    availabilitySeverity: availabilityAlertSeverity
  }
}

module serviceHealthAlertsModule './modules/monitoring/service-health-alerts.bicep' = {
  name: 'minimal-service-health-alerts-${environmentName}'
  scope: monitoringResourceGroup
  params: {
    environmentName: environmentName
    operationalActionGroupId: actionGroupsModule.outputs.operationalActionGroupId
    securityActionGroupId: actionGroupsModule.outputs.securityActionGroupId
    enabled: true
    tags: tags
  }
}

module availabilityTestModule './modules/monitoring/availability-test.bicep' = if (enableAvailabilityTest) {
  name: 'minimal-availability-test-${environmentName}'
  scope: monitoringResourceGroup
  params: {
    location: location
    webTestName: 'webtest-${projectCode}-${environmentName}-readiness'
    applicationInsightsId: applicationInsightsModule.outputs.applicationInsightsId
    testUrl: 'https://${regionalPlatformModule.outputs.webApps[0].hostname}/health/ready'
    actionGroupId: actionGroupsModule.outputs.operationalActionGroupId
    alertSeverity: availabilityAlertSeverity
    enableAlert: enableMetricAlerts
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Governance
// ---------------------------------------------------------------------------

module policyAssignmentsModule './modules/governance/policy-assignments.bicep' = {
  name: 'minimal-policy-assignments-${environmentName}'
  params: {
    environment: environmentName
    allowedLocations: allowedLocations
    requiredTagNames: requiredTagNames
    auditEffect: policyAuditEffect
  }
}

module budgetModule './modules/governance/budget.bicep' = {
  name: 'minimal-budget-${environmentName}'
  params: {
    budgetName: 'budget-${projectCode}-${environmentName}-minimal'
    budgetAmount: budgetAmount
    startDate: budgetStartDate
    endDate: budgetEndDate
    contactEmail: budgetContactEmail
    actionGroupIds: [
      actionGroupsModule.outputs.costActionGroupId
    ]
  }
}

// ---------------------------------------------------------------------------
// Outputs consumed by the deployment workflow
// ---------------------------------------------------------------------------

output regionalResourceGroupName string = regionalResourceGroupName
output networkResourceGroupName string = networkResourceGroupName
output monitoringResourceGroupName string = monitoringResourceGroupName

output primaryWebAppName string = regionalPlatformModule.outputs.webApps[0].webAppName
output primaryWebAppHostname string = regionalPlatformModule.outputs.webApps[0].hostname
output primaryWebAppUrl string = 'https://${regionalPlatformModule.outputs.webApps[0].hostname}'
output readinessProbeUrl string = 'https://${regionalPlatformModule.outputs.webApps[0].hostname}/health/ready'

output keyVaultName string = regionalPlatformModule.outputs.keyVaultName
output keyVaultUri string = regionalPlatformModule.outputs.keyVaultUri
output storageAccountName string = regionalPlatformModule.outputs.storageAccountName
output sqlServerFullyQualifiedDomainName string = regionalPlatformModule.outputs.sqlServerFullyQualifiedDomainName
output applicationInsightsName string = applicationInsightsName
output logAnalyticsWorkspaceName string = logAnalyticsWorkspaceName

output metricAlertCount int = metricAlertsModule.outputs.metricAlertCount
output policyAssignmentCount int = policyAssignmentsModule.outputs.policyAssignmentCount
