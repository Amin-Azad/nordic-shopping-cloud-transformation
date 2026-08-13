// Creates the approved resource-group structure for Nordic Shopping.
// Resource groups provide deployment, access-control, cost, and lifecycle boundaries.

targetScope = 'subscription'

@description('deployment environment used in resource group names and tags.')
param environment 'dev' | 'test' | 'prod'

@description('Short project code used in Azure resource names, for example nshop.')
@minLength(2)
@maxLength(10)
param projectCode string

@description('Azure region for the primary nordic shopping platform.')
param primaryLocation string

@description('azure region for the secondary disaster recovery platform.')
param secondaryLocation string

@description('team and business owner esponsible for the resource.')
@minLength(1)
param owner string

@description('cost center used for azure resource allocation and reporting.')
@minLength(1)
param costCenter string

@description('business criticality classification for the environment.')
@minLength(1)
param criticality string

@description('data classification for the environment.')
@minLength(1)
param dataClassification string

var mandatoryTags = {
  application: 'nordic-shopping'
  environment: environment
  owner: owner
  costCentre: costCenter
  dataClassification: dataClassification
  criticality: criticality
  managedBy: 'bicep'
}

var globalResourceGroupName = 'rg-${projectCode}-${environment}-global'
var primaryResourceGroupName = 'rg-${projectCode}-${environment}-weu'
var secondaryResourceGroupName = 'rg-${projectCode}-${environment}-swc'
var networkResourceGroupName = 'rg-${projectCode}-${environment}-network'
var monitoringResourceGroupName = 'rg-${projectCode}-${environment}-monitor'
var securityResourceGroupName = 'rg-${projectCode}-${environment}-security'

resource globalResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: globalResourceGroupName
  location: primaryLocation
  tags: mandatoryTags
}

resource primaryResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: primaryResourceGroupName
  location: primaryLocation
  tags: mandatoryTags
}

resource secondaryResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: secondaryResourceGroupName
  location: secondaryLocation
  tags: mandatoryTags
}

resource networkResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: networkResourceGroupName
  location: primaryLocation
  tags: mandatoryTags
}

resource monitoringResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: monitoringResourceGroupName
  location: primaryLocation
  tags: mandatoryTags
}

resource securityResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: securityResourceGroupName
  location: primaryLocation
  tags: mandatoryTags
}

@description('Resource-group names and ids used by deployment modules ')
output resourceGroups object = {
  global: {
    name: globalResourceGroup.name
    id: globalResourceGroup.id
  }
  primary: {
    name: primaryResourceGroup.name
    id: primaryResourceGroup.id
  }
  secondary: {
    name: secondaryResourceGroup.name
    id: secondaryResourceGroup.id
  }
  network: {
    name: networkResourceGroup.name
    id: networkResourceGroup.id
  }
  monitoring: {
    name: monitoringResourceGroup.name
    id: monitoringResourceGroup.id
  }
  security: {
    name: securityResourceGroup.name
    id: securityResourceGroup.id
  }
}
