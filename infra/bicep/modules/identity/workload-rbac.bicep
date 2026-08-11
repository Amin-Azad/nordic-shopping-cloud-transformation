targetScope = 'resourceGroup'

@description('Principal ID of the regional API Web App.')
param apiPrincipalId string = ''

@description('Assign regional Storage and Key Vault roles to the API identity.')
param enableApiDataAccess bool = false

@description('Name of the regional Storage account.')
param storageAccountName string = ''

@description('Blob containers that the API is allowed to access.')
param blobContainerNames array = []

@description('Name of the regional Key Vault.')
param keyVaultName string = ''

@description('Principal ID of the automation managed identity.')
param automationPrincipalId string = ''

@description('Assign Website Contributor to the automation identity.')
param enableAutomationAccess bool = false

@description('Web Apps that the automation identity can manage.')
param webAppNames array = []

@description('Principal ID of the optional AI operations managed identity.')
param aiOperationsPrincipalId string = ''

@description('Assign Azure OpenAI access to the AI operations identity.')
param enableAiAccess bool = false

@description('Name of the Azure AI Services account.')
param aiServicesAccountName string = ''

@description('Assign Log Analytics read access to the AI operations identity.')
param enableMonitoringAccess bool = false

@description('Name of the Log Analytics workspace.')
param logAnalyticsWorkspaceName string = ''

var storageBlobDataContributorRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
)

var keyVaultSecretsUserRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '4633458b-17de-408a-b874-0445c86b69e6'
)

var websiteContributorRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'de139f84-1756-47ae-9be6-808fbbe84772'
)

var cognitiveServicesOpenAiUserRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
)

var logAnalyticsReaderRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '73c42c96-874c-492b-b04d-ab87d138a893'
)

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' existing = if (enableApiDataAccess) {
  name: storageAccountName
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-01-01' existing = if (enableApiDataAccess) {
  parent: storageAccount
  name: 'default'
}

resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01' existing = [
  for containerName in blobContainerNames: if (enableApiDataAccess) {
    parent: blobService
    name: containerName
  }
]

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = if (enableApiDataAccess) {
  name: keyVaultName
}

resource webApps 'Microsoft.Web/sites@2025-03-01' existing = [
  for webAppName in webAppNames: if (enableAutomationAccess) {
    name: webAppName
  }
]

resource aiServicesAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = if (enableAiAccess) {
  name: aiServicesAccountName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' existing = if (enableMonitoringAccess) {
  name: logAnalyticsWorkspaceName
}

resource blobRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (containerName, index) in blobContainerNames: if (enableApiDataAccess) {
    name: guid(blobContainers[index].id, apiPrincipalId, storageBlobDataContributorRoleId)
    scope: blobContainers[index]
    properties: {
      principalId: apiPrincipalId
      principalType: 'ServicePrincipal'
      roleDefinitionId: storageBlobDataContributorRoleId
    }
  }
]

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableApiDataAccess) {
  name: guid(keyVault.id, apiPrincipalId, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    principalId: apiPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: keyVaultSecretsUserRoleId
  }
}

resource webAppRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (webAppName, index) in webAppNames: if (enableAutomationAccess) {
    name: guid(webApps[index].id, automationPrincipalId, websiteContributorRoleId)
    scope: webApps[index]
    properties: {
      principalId: automationPrincipalId
      principalType: 'ServicePrincipal'
      roleDefinitionId: websiteContributorRoleId
    }
  }
]

resource aiRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableAiAccess) {
  name: guid(aiServicesAccount.id, aiOperationsPrincipalId, cognitiveServicesOpenAiUserRoleId)
  scope: aiServicesAccount
  properties: {
    principalId: aiOperationsPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: cognitiveServicesOpenAiUserRoleId
  }
}

resource monitoringRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableMonitoringAccess) {
  name: guid(logAnalyticsWorkspace.id, aiOperationsPrincipalId, logAnalyticsReaderRoleId)
  scope: logAnalyticsWorkspace
  properties: {
    principalId: aiOperationsPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: logAnalyticsReaderRoleId
  }
}
