targetScope = 'resourceGroup'

@description('Azure region where the Log Analytics workspace is deployed.')
param location string

@description('Name of the Log Analytics workspace.')
@minLength(4)
@maxLength(63)
param workspaceName string

@description('Default workspace log retention period in days.')
@minValue(30)
@maxValue(730)
param retentionInDays int

@description('Daily ingestion limit in GB. Use -1 to disable the daily cap.')
@minValue(-1)
param dailyQuotaGb int = -1

@description('Tags applied to the Log Analytics workspace.')
param tags object

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaGb
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    features: {
      disableLocalAuth: true
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}
@description('Resource ID of the Log Analytics workspace.')
output workspaceId string = logAnalyticsWorkspace.id

@description('Name of the Log Analytics workspace.')
output workspaceName string = logAnalyticsWorkspace.name

@description('Immutable workspace customer ID.')
output workspaceCustomerId string = logAnalyticsWorkspace.properties.customerId

@description('Azure region of the Log Analytics workspace.')
output workspaceLocation string = logAnalyticsWorkspace.location
