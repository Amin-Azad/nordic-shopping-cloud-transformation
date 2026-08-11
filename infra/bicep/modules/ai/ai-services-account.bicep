targetScope = 'resourceGroup'

param location string
@minLength(2)
@maxLength(64)
param accountName string
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'
param enableDiagnostics bool = true
param logAnalyticsWorkspaceId string
param tags object

resource aiServicesAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: accountName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: accountName
    disableLocalAuth: true
    publicNetworkAccess: publicNetworkAccess
    dynamicThrottlingEnabled: true
    networkAcls: {
      defaultAction: publicNetworkAccess == 'Enabled' ? 'Allow' : 'Deny'
    }
  }
  tags: tags
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  name: 'send-to-log-analytics'
  scope: aiServicesAccount
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'audit'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output accountId string = aiServicesAccount.id
output accountName string = aiServicesAccount.name
output endpoint string = aiServicesAccount.properties.endpoint
output principalId string = aiServicesAccount.identity.principalId
