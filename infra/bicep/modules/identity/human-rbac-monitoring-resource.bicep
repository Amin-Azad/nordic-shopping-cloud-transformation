targetScope = 'resourceGroup'

param logAnalyticsWorkspaceName string
param operationsGroupObjectId string
param securityReadersGroupObjectId string
param auditorsGroupObjectId string

var logAnalyticsReaderRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '73c42c96-874c-492b-b04d-ab87d138a893'
)

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource operationsLogReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(logAnalyticsWorkspace.id, operationsGroupObjectId, logAnalyticsReaderRoleId)
  scope: logAnalyticsWorkspace
  properties: {
    principalId: operationsGroupObjectId
    principalType: 'Group'
    roleDefinitionId: logAnalyticsReaderRoleId
  }
}

resource securityLogReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(logAnalyticsWorkspace.id, securityReadersGroupObjectId, logAnalyticsReaderRoleId)
  scope: logAnalyticsWorkspace
  properties: {
    principalId: securityReadersGroupObjectId
    principalType: 'Group'
    roleDefinitionId: logAnalyticsReaderRoleId
  }
}

resource auditorLogReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(logAnalyticsWorkspace.id, auditorsGroupObjectId, logAnalyticsReaderRoleId)
  scope: logAnalyticsWorkspace
  properties: {
    principalId: auditorsGroupObjectId
    principalType: 'Group'
    roleDefinitionId: logAnalyticsReaderRoleId
  }
}
