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

var logRetentionInDays = environmentName == 'prod' ? 90 : 31
var logDailyQuotaGb = environmentName == 'prod' ? -1 : 1

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
    actionGroupIds: budgetActionGroupIds
  }
}
output deploymentEnvironment string = environmentName
output primaryRegion string = primaryLocation
output secondaryRegion string = secondaryLocation
output deploymentTags object = tags

output budgetResourceId string = budgetModule.outputs.budgetId
output budgetName string = budgetModule.outputs.deployedBudgetName

output deployedPolicyAssignmentCount int = policyAssignmentsModule.outputs.policyAssignmentCount

output logAnalyticsWorkspaceId string = logAnalyticsModule.outputs.workspaceId
output logAnalyticsWorkspaceName string = logAnalyticsModule.outputs.workspaceName
output logAnalyticsWorkspaceCustomerId string = logAnalyticsModule.outputs.workspaceCustomerId
output logAnalyticsWorkspaceLocation string = logAnalyticsModule.outputs.workspaceLocation
