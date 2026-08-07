targetScope = 'resourceGroup'

@description('Azure region where Application Insights is deployed.')
param location string

@description('Name of the Application Insights resource.')
@minLength(1)
@maxLength(260)
param applicationInsightsName string

@description('Resource ID of the connected Log Analytics workspace.')
param logAnalyticsWorkspaceResourceId string

@description('Percentage of application telemetry retained after sampling.')
@minValue(0)
@maxValue(100)
param samplingPercentage int = 100

@description('Tags applied to the Application Insights resource.')
param tags object

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceResourceId
    IngestionMode: 'LogAnalytics'
    SamplingPercentage: samplingPercentage
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('Resource ID of the Application Insights resource.')
output applicationInsightsId string = applicationInsights.id

@description('Name of the Application Insights resource.')
output applicationInsightsName string = applicationInsights.name

@description('Connection string used by applications to send telemetry.')
output connectionString string = applicationInsights.properties.ConnectionString
