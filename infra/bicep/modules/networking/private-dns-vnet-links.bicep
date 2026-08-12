targetScope = 'resourceGroup'

param primaryVirtualNetworkId string
param secondaryVirtualNetworkId string

var privateDnsZoneNames = [
  'privatelink.${environment().suffixes.sqlServerHostname}'
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.vaultcore.azure.net'
  'privatelink.openai.azure.com'
  'privatelink.cognitiveservices.azure.com'
]

resource privateDnsZones 'Microsoft.Network/privateDnsZones@2024-06-01' existing = [
  for zoneName in privateDnsZoneNames: {
    name: zoneName
  }
]

resource primaryVirtualNetworkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [
  for (zoneName, index) in privateDnsZoneNames: {
    parent: privateDnsZones[index]
    name: 'link-primary-vnet'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: primaryVirtualNetworkId
      }
    }
  }
]

resource secondaryVirtualNetworkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [
  for (zoneName, index) in privateDnsZoneNames: {
    parent: privateDnsZones[index]
    name: 'link-secondary-vnet'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: secondaryVirtualNetworkId
      }
    }
  }
]
