targetScope = 'resourceGroup'

param location string

@minLength(3)
@maxLength(24)
param storageAccountName string
param skuName string = 'Standard_LRS'
param publicNetworkAccess string = 'Enabled'

@minValue(1)
@maxValue(365)
param softDeleteRetentionDays int = 7
param enableVersioning bool = true
param enableDiagnostics bool = true
param logAnalyticsWorkspaceId string
param containerNames array = [
  'uploads'
  'assets'
  'app-data'
  'logs'
  'backups'
]
param tags object

@minValue(1)
@maxValue(365)
param oldVersionRetentionDays int = 30

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    publicNetworkAccess: publicNetworkAccess
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: true
    }
    allowCrossTenantReplication: false
    defaultToOAuthAuthentication: true
  }
}
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    isVersioningEnabled: enableVersioning
    deleteRetentionPolicy: {
      enabled: true
      days: softDeleteRetentionDays
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: softDeleteRetentionDays
    }
  }
}
resource blobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01' = [
  for containerName in containerNames: {
    parent: blobService
    name: containerName
    properties: {
      publicAccess: 'None'
    }
  }
]
#disable-next-line use-recent-api-versions
resource blobDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  scope: blobService
  name: 'send-blob-logs-to-law'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}
resource lifecyclePolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2025-01-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          name: 'delete-old-blob-versions'
          enabled: true
          type: 'Lifecycle'
          definition: {
            actions: {
              version: {
                delete: {
                  daysAfterCreationGreaterThan: oldVersionRetentionDays
                }
              }
            }
            filters: {
              blobTypes: [
                'blockBlob'
              ]
            }
          }
        }
      ]
    }
  }
}
output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
output blobServiceId string = blobService.id
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
