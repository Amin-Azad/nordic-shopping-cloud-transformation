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
