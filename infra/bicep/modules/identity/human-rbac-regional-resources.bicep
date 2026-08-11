targetScope = 'resourceGroup'

param environmentName 'dev' | 'test' | 'prod'
param developersGroupObjectId string
param databaseAdministratorsGroupObjectId string
param webAppNames array
param sqlServerName string

var readerRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'acdd72a7-3385-48ef-bd42-f606fba81ae7'
)
var websiteContributorRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'de139f84-1756-47ae-9be6-808fbbe84772'
)
var sqlServerContributorRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '6d8ee4ec-f05a-4a1d-8b00-a9b17e38b437'
)
var developerRoleId = environmentName == 'prod' ? readerRoleId : websiteContributorRoleId

resource webApps 'Microsoft.Web/sites@2025-03-01' existing = [
  for webAppName in webAppNames: {
    name: webAppName
  }
]

resource sqlServer 'Microsoft.Sql/servers@2025-01-01' existing = {
  name: sqlServerName
}

resource developerAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (webAppName, index) in webAppNames: {
    name: guid(webApps[index].id, developersGroupObjectId, developerRoleId)
    scope: webApps[index]
    properties: {
      principalId: developersGroupObjectId
      principalType: 'Group'
      roleDefinitionId: developerRoleId
    }
  }
]

resource sqlServerContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(sqlServer.id, databaseAdministratorsGroupObjectId, sqlServerContributorRoleId)
  scope: sqlServer
  properties: {
    principalId: databaseAdministratorsGroupObjectId
    principalType: 'Group'
    roleDefinitionId: sqlServerContributorRoleId
  }
}
