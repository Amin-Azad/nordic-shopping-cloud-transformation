targetScope = 'resourceGroup'

@description('Azure region where the virtual network will be deployed.')
param location string

@description('Name of the virtual network.')
param virtualNetworkName string

@description('Address space assigned to the virtual network.')
param virtualNetworkAddressPrefix string

@description('Name of the App Service integration subnet.')
param appServiceSubnetName string = 'snet-app-integration'

@description('Address prefix assigned to the App Service integration subnet.')
param appServiceSubnetAddressPrefix string

@description('Resource ID of the NSG attached to the App Service integration subnet.')
param appServiceNetworkSecurityGroupId string

@description('Name of the private endpoint subnet.')
param privateEndpointSubnetName string = 'snet-private-endpoints'

@description('Address prefix assigned to the private endpoint subnet.')
param privateEndpointSubnetAddressPrefix string

@description('Resource ID of the NSG attached to the private endpoint subnet.')
param privateEndpointNetworkSecurityGroupId string

@description('Tags applied to the virtual network.')
param tags object = {}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2025-07-01' = {
  name: virtualNetworkName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
  }
}
resource appServiceSubnet 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  parent: virtualNetwork
  name: appServiceSubnetName
  properties: {
    addressPrefix: appServiceSubnetAddressPrefix
    networkSecurityGroup: {
      id: appServiceNetworkSecurityGroupId
    }
    delegations: [
      {
        name: 'app-service-delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverFarms'
        }
      }
    ]
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}
resource privateEndpointSubnet 'Microsoft.Network/virtualNetworks/subnets@2025-07-01' = {
  parent: virtualNetwork
  name: privateEndpointSubnetName
  properties: {
    addressPrefix: privateEndpointSubnetAddressPrefix
    networkSecurityGroup: {
      id: privateEndpointNetworkSecurityGroupId
    }
    privateEndpointNetworkPolicies: 'NetworkSecurityGroupEnabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
  dependsOn: [
    appServiceSubnet
  ]
}

output virtualNetworkId string = virtualNetwork.id
output virtualNetworkName string = virtualNetwork.name
output appServiceSubnetId string = appServiceSubnet.id
output privateEndpointSubnetId string = privateEndpointSubnet.id
