using '../../main.bicep'

param environmentName = 'dev'
param primaryLocation = 'westeurope'
param secondaryLocation = 'swedencentral'

param owner = 'Amin Azad'
param costCenter = 'portfolio'
param criticality = 'low'
param dataClassification = 'internal'

param tags = {
  project: 'nordic-shopping-cloud-transformation'
  environment: 'dev'
  managedBy: 'bicep'
  owner: 'Amin Azad'
  costCentre: 'portfolio'
}
