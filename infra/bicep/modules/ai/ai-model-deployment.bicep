targetScope = 'resourceGroup'

param aiServicesAccountName string
param deploymentName string
param modelName string
param modelVersion string

@allowed([
  'Standard'
  'GlobalStandard'
  'DataZoneStandard'
])
param skuName string

@minValue(1)
param capacity int

param enableModelDeployment bool = false

resource aiServicesAccount 'Microsoft.CognitiveServices/accounts@2025-09-01' existing = {
  name: aiServicesAccountName
}

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-09-01' = if (enableModelDeployment) {
  parent: aiServicesAccount
  name: deploymentName
  sku: {
    name: skuName
    capacity: capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
    versionUpgradeOption: 'NoAutoUpgrade'
  }
}

output deploymentName string = enableModelDeployment ? modelDeployment.name : ''
output deploymentId string = enableModelDeployment ? modelDeployment.id : ''
output modelDeploymentEnabled bool = enableModelDeployment
