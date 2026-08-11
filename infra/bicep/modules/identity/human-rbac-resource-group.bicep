targetScope = 'resourceGroup'

param assignPlatformContributor bool
param assignOperationsRoles bool
param platformAdministratorsGroupObjectId string
param operationsGroupObjectId string
param auditorsGroupObjectId string

var contributorRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'b24988ac-6180-42a0-ab88-20f7382dd24c'
)
var readerRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'acdd72a7-3385-48ef-bd42-f606fba81ae7'
)
var monitoringReaderRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
)

resource platformContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (assignPlatformContributor) {
  name: guid(resourceGroup().id, platformAdministratorsGroupObjectId, contributorRoleId)
  properties: {
    principalId: platformAdministratorsGroupObjectId
    principalType: 'Group'
    roleDefinitionId: contributorRoleId
  }
}

resource operationsReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (assignOperationsRoles) {
  name: guid(resourceGroup().id, operationsGroupObjectId, readerRoleId)
  properties: {
    principalId: operationsGroupObjectId
    principalType: 'Group'
    roleDefinitionId: readerRoleId
  }
}

resource operationsMonitoringReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (assignOperationsRoles) {
  name: guid(resourceGroup().id, operationsGroupObjectId, monitoringReaderRoleId)
  properties: {
    principalId: operationsGroupObjectId
    principalType: 'Group'
    roleDefinitionId: monitoringReaderRoleId
  }
}

resource auditorReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, auditorsGroupObjectId, readerRoleId)
  properties: {
    principalId: auditorsGroupObjectId
    principalType: 'Group'
    roleDefinitionId: readerRoleId
  }
}
