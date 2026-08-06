targetScope = 'subscription'

metadata name = 'Nordic Shopping Cloud Transformation'
metadata description = 'Subscription-level orchestration template for Nordic Shopping Azure infrastructure.'

@description('Deployment environment.')
param environmentName 'dev' | 'test' | 'prod'

@description('Primary Azure region.')
param primaryLocation string = 'westeurope'

@description('Secondary Azure region used for disaster recovery.')
param secondaryLocation string = 'swedencentral'

@description('Readable project name used in governance tags.')
param projectName string = 'Nordic Shopping Cloud Transformation'

@description('Short project code used in Azure resource names.')
@minLength(2)
@maxLength(10)
param projectCode string = 'nshop'

@description('Team or business owner responsible for the environment.')
@minLength(1)
param owner string

@description('Cost center used for Azure cost allocation and reporting.')
@minLength(1)
param costCenter string

@description('Business criticality classification for the environment.')
@minLength(1)
param criticality string

@description('Data classification applied to the environment.')
@minLength(1)
param dataClassification string

@description('Tags applied to resources deployed by this project.')
param tags object = {
  project: 'nordic-shopping-cloud-transformation'
  environment: environmentName
  managedBy: 'bicep'
}
module resourceGroupsModule './modules/governance/resource-groups.bicep' = {
  name: 'deploy-resource-groups-${environmentName}'
  params: {
    environment: environmentName
    projectName: projectName
    projectCode: projectCode
    primaryLocation: primaryLocation
    secondaryLocation: secondaryLocation
    owner: owner
    costCenter: costCenter
    criticality: criticality
    dataClassification: dataClassification
  }
}
output deploymentEnvironment string = environmentName
output primaryRegion string = primaryLocation
output secondaryRegion string = secondaryLocation
output deploymentTags object = tags
