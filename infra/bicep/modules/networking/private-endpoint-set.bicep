targetScope = 'resourceGroup'

param environmentName string
param projectCode string
param regionCode string
param location string

param privateEndpointSubnetId string

param storageAccountId string
param keyVaultId string
param sqlServerId string

param blobPrivateDnsZoneId string
param keyVaultPrivateDnsZoneId string
param sqlPrivateDnsZoneId string

param enableAzureOpenAIPrivateEndpoint bool = false
param azureOpenAIAccountId string = ''
param azureOpenAIPrivateDnsZoneId string = ''

param tags object = {}

module storageBlobPrivateEndpoint './private-endpoint.bicep' = {
  name: 'deploy-storage-blob-private-endpoint'
  params: {
    location: location
    privateEndpointName: 'pe-${projectCode}-${environmentName}-blob-${regionCode}'
    targetResourceId: storageAccountId
    groupId: 'blob'
    subnetId: privateEndpointSubnetId
    privateDnsZoneId: blobPrivateDnsZoneId
    tags: tags
  }
}

module keyVaultPrivateEndpoint './private-endpoint.bicep' = {
  name: 'deploy-key-vault-private-endpoint'
  params: {
    location: location
    privateEndpointName: 'pe-${projectCode}-${environmentName}-kv-${regionCode}'
    targetResourceId: keyVaultId
    groupId: 'vault'
    subnetId: privateEndpointSubnetId
    privateDnsZoneId: keyVaultPrivateDnsZoneId
    tags: tags
  }
}

module sqlPrivateEndpoint './private-endpoint.bicep' = {
  name: 'deploy-sql-private-endpoint'
  params: {
    location: location
    privateEndpointName: 'pe-${projectCode}-${environmentName}-sql-${regionCode}'
    targetResourceId: sqlServerId
    groupId: 'sqlServer'
    subnetId: privateEndpointSubnetId
    privateDnsZoneId: sqlPrivateDnsZoneId
    tags: tags
  }
}

module azureOpenAIPrivateEndpoint './private-endpoint.bicep' = if (enableAzureOpenAIPrivateEndpoint) {
  name: 'deploy-azure-openai-private-endpoint'
  params: {
    location: location
    privateEndpointName: 'pe-${projectCode}-${environmentName}-openai-${regionCode}'
    targetResourceId: azureOpenAIAccountId
    groupId: 'account'
    subnetId: privateEndpointSubnetId
    privateDnsZoneId: azureOpenAIPrivateDnsZoneId
    tags: tags
  }
}

output storageBlobPrivateEndpointId string = storageBlobPrivateEndpoint.outputs.privateEndpointId
output keyVaultPrivateEndpointId string = keyVaultPrivateEndpoint.outputs.privateEndpointId
output sqlPrivateEndpointId string = sqlPrivateEndpoint.outputs.privateEndpointId

output azureOpenAIPrivateEndpointId string = enableAzureOpenAIPrivateEndpoint
  ? azureOpenAIPrivateEndpoint!.outputs.privateEndpointId
  : ''
