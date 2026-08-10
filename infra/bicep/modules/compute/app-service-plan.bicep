targetScope = 'resourceGroup'

param location string
param appServicePlanName string
param skuName string
@minValue(1)
param workerCount int
param zoneRedundant bool = false
param tags object

resource appServicePlan 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: skuName
    capacity: workerCount
  }
  kind: 'linux'
  properties: {
    reserved: true
    zoneRedundant: zoneRedundant
  }
}

output appServicePlanId string = appServicePlan.id
output appServicePlanName string = appServicePlan.name
output appServicePlanLocation string = appServicePlan.location
