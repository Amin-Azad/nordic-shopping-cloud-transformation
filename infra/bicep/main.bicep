targetScope = 'subscription'

metadata name = 'Nordic Shopping Cloud Transformation'
metadata description = 'Subscription-level orchestration template for Nordic Shopping Azure infrastructure.'

@description('Deployment environment.')
@allowed([
  'dev'
  'prod'
])
param environmentName string

@description('Primary Azure region.')
param primaryLocation string = 'westeurope'

@description('Secondary Azure region used for disaster recovery.')
param secondaryLocation string = 'swedencentral'

@description('Tags applied to resources deployed by this project.')
param tags object = {
  project: 'nordic-shopping-cloud-transformation'
  environment: environmentName
  managedBy: 'bicep'
}

output deploymentEnvironment string = environmentName
output primaryRegion string = primaryLocation
output secondaryRegion string = secondaryLocation
output deploymentTags object = tags
