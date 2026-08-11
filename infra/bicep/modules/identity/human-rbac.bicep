targetScope = 'subscription'

param environmentName 'dev' | 'test' | 'prod'

param platformAdministratorsGroupObjectId string
param developersGroupObjectId string
param operationsGroupObjectId string
param securityReadersGroupObjectId string
param costReadersGroupObjectId string
param databaseAdministratorsGroupObjectId string
param auditorsGroupObjectId string

param projectResourceGroupNames array
param operationsResourceGroupNames array
param primaryResourceGroupName string
param secondaryResourceGroupName string
param monitoringResourceGroupName string
param primaryWebAppNames array
param secondaryWebAppNames array
param primarySqlServerName string
param secondarySqlServerName string
param logAnalyticsWorkspaceName string

var securityReaderRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '39bc4728-0917-49c7-9d2c-d95423bc2eb4'
)

var costManagementReaderRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '72fafb9e-0641-4937-9268-a91bfd8191a3'
)

resource securityReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, securityReadersGroupObjectId, securityReaderRoleId)
  properties: {
    principalId: securityReadersGroupObjectId
    principalType: 'Group'
    roleDefinitionId: securityReaderRoleId
  }
}

resource costManagementReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, costReadersGroupObjectId, costManagementReaderRoleId)
  properties: {
    principalId: costReadersGroupObjectId
    principalType: 'Group'
    roleDefinitionId: costManagementReaderRoleId
  }
}

module projectResourceGroupRbac './human-rbac-resource-group.bicep' = [
  for resourceGroupName in projectResourceGroupNames: {
    name: 'human-rbac-project-${uniqueString(resourceGroupName)}'
    scope: resourceGroup(resourceGroupName)
    params: {
      assignPlatformContributor: true
      assignOperationsRoles: contains(operationsResourceGroupNames, resourceGroupName)
      platformAdministratorsGroupObjectId: platformAdministratorsGroupObjectId
      operationsGroupObjectId: operationsGroupObjectId
      auditorsGroupObjectId: auditorsGroupObjectId
    }
  }
]

module primaryRegionalRbac './human-rbac-regional-resources.bicep' = {
  name: 'human-rbac-regional-primary'
  scope: resourceGroup(primaryResourceGroupName)
  params: {
    environmentName: environmentName
    developersGroupObjectId: developersGroupObjectId
    databaseAdministratorsGroupObjectId: databaseAdministratorsGroupObjectId
    webAppNames: primaryWebAppNames
    sqlServerName: primarySqlServerName
  }
}

module secondaryRegionalRbac './human-rbac-regional-resources.bicep' = {
  name: 'human-rbac-regional-secondary'
  scope: resourceGroup(secondaryResourceGroupName)
  params: {
    environmentName: environmentName
    developersGroupObjectId: developersGroupObjectId
    databaseAdministratorsGroupObjectId: databaseAdministratorsGroupObjectId
    webAppNames: secondaryWebAppNames
    sqlServerName: secondarySqlServerName
  }
}

module monitoringResourceRbac './human-rbac-monitoring-resource.bicep' = {
  name: 'human-rbac-monitoring-resource'
  scope: resourceGroup(monitoringResourceGroupName)
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    operationsGroupObjectId: operationsGroupObjectId
    securityReadersGroupObjectId: securityReadersGroupObjectId
    auditorsGroupObjectId: auditorsGroupObjectId
  }
}
