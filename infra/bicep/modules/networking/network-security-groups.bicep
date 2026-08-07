targetScope = 'resourceGroup'

param environmentName string
param projectCode string = 'nshop'
param regionCode string
param location string = resourceGroup().location

//subnet address ranges are used as rule sources and destinations.
param appIntegrationSubnetPrefix string

@description('Address prefix of the private endpoint subnet.')
param privateEndpointSubnetPrefix string

param tags object

var appServiceNsgName = 'nsg-${projectCode}-${environmentName}-${regionCode}-app'
var privateEndpointNsgName = 'nsg-${projectCode}-${environmentName}-${regionCode}-pe'

resource appServiceNsg 'Microsoft.Network/networkSecurityGroups@2025-07-01' = {
  name: appServiceNsgName
  location: location
  tags: union(tags, {
    ResourceType: 'Network Security Group'
    NetworkPurpose: 'App Service VNet integration'
  })
  properties: {
    securityRules: [
      {
        name: 'Allow-DNS-Outbound'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRanges: [
            '53'
          ]
          sourceAddressPrefix: appIntegrationSubnetPrefix
          destinationAddressPrefix: '168.63.129.16'
        }
      }
      {
        name: 'Allow-HTTPS-To-PrivateEndpoints'
        properties: {
          priority: 110
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: appIntegrationSubnetPrefix
          destinationAddressPrefix: privateEndpointSubnetPrefix
        }
      }
      {
        name: 'Allow-SQL-To-PrivateEndpoints'
        properties: {
          priority: 120
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: appIntegrationSubnetPrefix
          destinationAddressPrefix: privateEndpointSubnetPrefix
        }
      }
      {
        name: 'Allow-AzureFiles-To-PrivateEndpoints'
        properties: {
          priority: 130
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '445'
          sourceAddressPrefix: appIntegrationSubnetPrefix
          destinationAddressPrefix: privateEndpointSubnetPrefix
        }
      }
      {
        name: 'Allow-AzureMonitor-Outbound'
        properties: {
          priority: 140
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: appIntegrationSubnetPrefix
          destinationAddressPrefix: 'AzureMonitor'
        }
      }
      {
        name: 'Allow-HTTPS-Internet-Outbound'
        properties: {
          priority: 150
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: appIntegrationSubnetPrefix
          destinationAddressPrefix: 'Internet'
        }
      }
      {
        name: 'Deny-Other-Internet-Outbound'
        properties: {
          priority: 4000
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: appIntegrationSubnetPrefix
          destinationAddressPrefix: 'Internet'
        }
      }
    ]
  }
}

resource privateEndpointNsg 'Microsoft.Network/networkSecurityGroups@2025-07-01' = {
  name: privateEndpointNsgName
  location: location
  tags: union(tags, {
    ResourceType: 'Network Security Group'
    NetworkPurpose: 'Private endpoints'
  })
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTPS-From-AppSubnet'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: appIntegrationSubnetPrefix
          destinationAddressPrefix: privateEndpointSubnetPrefix
        }
      }
      {
        name: 'Allow-SQL-From-AppSubnet'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: appIntegrationSubnetPrefix
          destinationAddressPrefix: privateEndpointSubnetPrefix
        }
      }
      {
        name: 'Allow-AzureFiles-From-AppSubnet'
        properties: {
          priority: 120
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '445'
          sourceAddressPrefix: appIntegrationSubnetPrefix
          destinationAddressPrefix: privateEndpointSubnetPrefix
        }
      }
      {
        name: 'Deny-Other-VNet-Inbound'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: privateEndpointSubnetPrefix
        }
      }
    ]
  }
}

output appServiceNsgId string = appServiceNsg.id
output appServiceNsgName string = appServiceNsg.name
output privateEndpointNsgId string = privateEndpointNsg.id
output privateEndpointNsgName string = privateEndpointNsg.name
