targetScope = 'resourceGroup'

param primaryVirtualNetworkId string
param secondaryVirtualNetworkId string

var regionalPrivateDnsZoneNames = [
  'privatelink${environment().suffixes.sqlServerHostname}'
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.vaultcore.azure.net'
]

var primaryOnlyPrivateDnsZoneNames = [
  'privatelink.openai.azure.com'
]

resource regionalPrivateDnsZones 'Microsoft.Network/privateDnsZones@2024-06-01' existing = [
  for zoneName in regionalPrivateDnsZoneNames: {
    name: zoneName
  }
]

resource primaryOnlyPrivateDnsZones 'Microsoft.Network/privateDnsZones@2024-06-01' existing = [
  for zoneName in primaryOnlyPrivateDnsZoneNames: {
    name: zoneName
  }
]

resource primaryRegionalVirtualNetworkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [
  for (zoneName, index) in regionalPrivateDnsZoneNames: {
    parent: regionalPrivateDnsZones[index]
    name: 'link-${last(split(primaryVirtualNetworkId, '/'))}'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: primaryVirtualNetworkId
      }
    }
  }
]

resource secondaryRegionalVirtualNetworkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [
  for (zoneName, index) in regionalPrivateDnsZoneNames: {
    parent: regionalPrivateDnsZones[index]
    name: 'link-${last(split(secondaryVirtualNetworkId, '/'))}'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: secondaryVirtualNetworkId
      }
    }
  }
]

resource primaryOnlyVirtualNetworkLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [
  for (zoneName, index) in primaryOnlyPrivateDnsZoneNames: {
    parent: primaryOnlyPrivateDnsZones[index]
    name: 'link-${last(split(primaryVirtualNetworkId, '/'))}'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: primaryVirtualNetworkId
      }
    }
  }
]
