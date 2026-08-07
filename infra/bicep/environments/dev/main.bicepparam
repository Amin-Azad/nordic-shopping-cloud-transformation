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
  costCenter: 'portfolio'
}
param budgetAmount = 16500
param budgetStartDate = '2026-08-01T00:00:00Z'
param budgetEndDate = '2031-08-01T00:00:00Z'

param budgetContactEmail = readEnvironmentVariable('BUDGET_ALERT_EMAIL')
