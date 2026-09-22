targetScope = 'resourceGroup'

param location string
param webAppName string
param appServicePlanId string
param appServiceSubnetId string
param logAnalyticsWorkspaceId string
param applicationInsightsConnectionString string

@allowed([
  'NODE|20-lts'
  'NODE|22-lts'
  'NODE|24-lts'
])
param linuxRuntime string = 'NODE|20-lts'

param healthCheckPath string = '/health/ready'
param createStagingSlot bool = false
param appSettings object = {}

@description('Allows direct public ingress. Keep false whenever Front Door fronts this app.')
param allowDirectIngress bool = false

@description('Key Vault URI exposed to the application for managed-identity secret access.')
param keyVaultUri string = ''

param tags object

var defaultAppSettings = {
  APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsightsConnectionString
  ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
  WEBSITE_NODE_DEFAULT_VERSION: '~20'
  WEBSITE_HEALTHCHECK_MAXPINGFAILURES: '3'
  WEBSITE_DNS_SERVER: '168.63.129.16'
  SCM_DO_BUILD_DURING_DEPLOYMENT: 'true'
  KEY_VAULT_URI: keyVaultUri
}

var ingressDefaultAction = allowDirectIngress ? 'Allow' : 'Deny'

var combinedAppSettings = union(defaultAppSettings, appSettings)

resource webApp 'Microsoft.Web/sites@2025-03-01' = {
  name: webAppName
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    virtualNetworkSubnetId: appServiceSubnetId
    siteConfig: {
      linuxFxVersion: linuxRuntime
      alwaysOn: true
      ftpsState: 'Disabled'
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      healthCheckPath: healthCheckPath
      vnetRouteAllEnabled: true
      ipSecurityRestrictionsDefaultAction: ingressDefaultAction
      appSettings: [
        for setting in items(combinedAppSettings): {
          name: setting.key
          value: string(setting.value)
        }
      ]
    }
  }
}

resource ftpPublishingPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2025-03-01' = {
  parent: webApp
  name: 'ftp'
  properties: {
    allow: false
  }
}

resource scmPublishingPolicy 'Microsoft.Web/sites/basicPublishingCredentialsPolicies@2025-03-01' = {
  parent: webApp
  name: 'scm'
  properties: {
    allow: false
  }
}

#disable-next-line use-recent-api-versions
resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: webApp
  name: 'send-to-log-analytics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

resource stagingSlot 'Microsoft.Web/sites/slots@2025-03-01' = if (createStagingSlot) {
  parent: webApp
  name: 'staging'
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    virtualNetworkSubnetId: appServiceSubnetId
    siteConfig: {
      linuxFxVersion: linuxRuntime
      alwaysOn: true
      ftpsState: 'Disabled'
      http20Enabled: true
      minTlsVersion: '1.2'
      scmMinTlsVersion: '1.2'
      healthCheckPath: healthCheckPath
      vnetRouteAllEnabled: true
      ipSecurityRestrictionsDefaultAction: ingressDefaultAction
      appSettings: [
        for setting in items(combinedAppSettings): {
          name: setting.key
          value: string(setting.value)
        }
      ]
    }
  }
}

output webAppId string = webApp.id
output webAppName string = webApp.name
output webAppHostname string = webApp.properties.defaultHostName
output webAppPrincipalId string = webApp.identity.principalId
output stagingSlotName string = createStagingSlot ? stagingSlot!.name : ''
output stagingSlotPrincipalId string = createStagingSlot ? stagingSlot!.identity.principalId : ''
