targetScope = 'resourceGroup'

param location string
param automationIdentityName string
param aiOperationsIdentityName string
param enableAiOperationsIdentity bool = false
param tags object

resource automationIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: automationIdentityName
  location: location
  tags: tags
}

resource aiOperationsIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = if (enableAiOperationsIdentity) {
  name: aiOperationsIdentityName
  location: location
  tags: tags
}

output automationIdentityResourceId string = automationIdentity.id
output automationIdentityPrincipalId string = automationIdentity.properties.principalId
output automationIdentityClientId string = automationIdentity.properties.clientId

output aiOperationsIdentityResourceId string = enableAiOperationsIdentity ? aiOperationsIdentity!.id : ''

output aiOperationsIdentityPrincipalId string = enableAiOperationsIdentity
  ? aiOperationsIdentity!.properties.principalId
  : ''

output aiOperationsIdentityClientId string = enableAiOperationsIdentity ? aiOperationsIdentity!.properties.clientId : ''
