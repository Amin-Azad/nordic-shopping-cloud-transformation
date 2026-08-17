targetScope = 'resourceGroup'

//region where the Key Vault will be deployed
param location string

@minLength(3)
@maxLength(24)
param keyVaultName string
param logAnalyticsWorkspaceId string

//Controls access to the Key Vault through the public network
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

//Enables purge protection. Use false only for temporary development environments.
param enablePurgeProtection bool = true

//Number of days deleted Key Vault data remains recoverable.
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90
param tags object

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: union(
    {
      tenantId: tenant().tenantId
      enableRbacAuthorization: true
      enableSoftDelete: true
      softDeleteRetentionInDays: softDeleteRetentionInDays
      publicNetworkAccess: publicNetworkAccess
      networkAcls: {
        bypass: 'AzureServices'
        defaultAction: publicNetworkAccess == 'Disabled' ? 'Deny' : 'Allow'
      }
      sku: {
        family: 'A'
        name: 'standard'
      }
    },
    enablePurgeProtection
      ? {
          enablePurgeProtection: true
        }
      : {}
  )
}

#disable-next-line use-recent-api-versions
resource keyVaultDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-log-analytics'
  scope: keyVault
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
output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
