using '../../main.bicep'

param environmentName = 'dev'
param primaryLocation = 'westeurope'
param secondaryLocation = 'swedencentral'

param tags = {
  project: 'nordic-shopping-cloud-transformation'
  environment: 'dev'
  managedBy: 'bicep'
  owner: 'Amin Azad'
  costCentre: 'portfolio'
}
