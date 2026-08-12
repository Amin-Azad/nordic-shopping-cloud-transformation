param environmentName string
param frontDoorProfileId string
param appServicePlanIds array
param webAppIds array
param sqlDatabaseIds array
param storageAccountIds array
param keyVaultIds array
param operationalActionGroupId string
param securityActionGroupId string
param enabled bool = true

param frontDoorOriginHealthThreshold int = 90
param frontDoor5xxThreshold int = 5
param appServiceCpuThreshold int = 80
param appService5xxThreshold int = 10
param sqlCpuThreshold int = 80
param sqlConnectionFailureThreshold int = 5
param sqlStorageThreshold int = 80
param storageAvailabilityThreshold int = 99
param keyVaultAvailabilityThreshold int = 99
param keyVaultFailureThreshold int = 5

@allowed([0, 1, 2, 3, 4])
param availabilitySeverity int = 1

@allowed([0, 1, 2, 3, 4])
param performanceSeverity int = 2

@allowed([0, 1, 2, 3, 4])
param securitySeverity int = 1

resource frontDoorOriginHealthAlert 'Microsoft.Insights/metricAlerts@2026-01-01' = {
  name: 'alert-${environmentName}-frontdoor-origin-health'
  location: 'global'
  properties: {
    description: 'Front Door origin health is below the approved threshold.'
    severity: availabilitySeverity
    enabled: enabled
    scopes: [frontDoorProfileId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'OriginHealthBelowThreshold'
          metricNamespace: 'Microsoft.Cdn/profiles'
          metricName: 'OriginHealthPercentage'
          operator: 'LessThan'
          threshold: frontDoorOriginHealthThreshold
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [{ actionGroupId: operationalActionGroupId }]
  }
}

resource frontDoor5xxAlert 'Microsoft.Insights/metricAlerts@2026-01-01' = {
  name: 'alert-${environmentName}-frontdoor-5xx'
  location: 'global'
  properties: {
    description: 'Front Door 5xx response percentage is above the approved threshold.'
    severity: availabilitySeverity
    enabled: enabled
    scopes: [frontDoorProfileId]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'FrontDoor5xxAboveThreshold'
          metricNamespace: 'Microsoft.Cdn/profiles'
          metricName: 'Percentage5XX'
          operator: 'GreaterThan'
          threshold: frontDoor5xxThreshold
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [{ actionGroupId: operationalActionGroupId }]
  }
}

resource appServiceCpuAlerts 'Microsoft.Insights/metricAlerts@2026-01-01' = [
  for (planId, index) in appServicePlanIds: {
    name: 'alert-${environmentName}-app-plan-${index + 1}-cpu'
    location: 'global'
    properties: {
      description: 'App Service plan CPU is above the approved threshold.'
      severity: performanceSeverity
      enabled: enabled
      scopes: [planId]
      evaluationFrequency: 'PT5M'
      windowSize: 'PT5M'
      criteria: {
        'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
        allOf: [
          {
            name: 'CpuAboveThreshold'
            metricNamespace: 'Microsoft.Web/serverfarms'
            metricName: 'CpuPercentage'
            operator: 'GreaterThan'
            threshold: appServiceCpuThreshold
            timeAggregation: 'Average'
            criterionType: 'StaticThresholdCriterion'
          }
        ]
      }
      actions: [{ actionGroupId: operationalActionGroupId }]
    }
  }
]

resource webApp5xxAlerts 'Microsoft.Insights/metricAlerts@2026-01-01' = [
  for (webAppId, index) in webAppIds: {
    name: 'alert-${environmentName}-webapp-${index + 1}-5xx'
    location: 'global'
    properties: {
      description: 'Web App HTTP 5xx responses are above the approved threshold.'
      severity: availabilitySeverity
      enabled: enabled
      scopes: [webAppId]
      evaluationFrequency: 'PT5M'
      windowSize: 'PT5M'
      criteria: {
        'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
        allOf: [
          {
            name: 'Http5xxAboveThreshold'
            metricNamespace: 'Microsoft.Web/sites'
            metricName: 'Http5xx'
            operator: 'GreaterThan'
            threshold: appService5xxThreshold
            timeAggregation: 'Total'
            criterionType: 'StaticThresholdCriterion'
          }
        ]
      }
      actions: [{ actionGroupId: operationalActionGroupId }]
    }
  }
]

resource webAppHealthAlerts 'Microsoft.Insights/metricAlerts@2026-01-01' = [
  for (webAppId, index) in webAppIds: {
    name: 'alert-${environmentName}-webapp-${index + 1}-health'
    location: 'global'
    properties: {
      description: 'Web App health check reports no healthy instance.'
      severity: availabilitySeverity
      enabled: enabled
      scopes: [webAppId]
      evaluationFrequency: 'PT5M'
      windowSize: 'PT5M'
      criteria: {
        'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
        allOf: [
          {
            name: 'NoHealthyInstance'
            metricNamespace: 'Microsoft.Web/sites'
            metricName: 'HealthCheckStatus'
            operator: 'LessThan'
            threshold: 1
            timeAggregation: 'Average'
            criterionType: 'StaticThresholdCriterion'
          }
        ]
      }
      actions: [{ actionGroupId: operationalActionGroupId }]
    }
  }
]

resource sqlCpuAlerts 'Microsoft.Insights/metricAlerts@2026-01-01' = [
  for (databaseId, index) in sqlDatabaseIds: {
    name: 'alert-${environmentName}-sql-${index + 1}-cpu'
    location: 'global'
    properties: {
      description: 'SQL Database CPU is above the approved threshold.'
      severity: performanceSeverity
      enabled: enabled
      scopes: [databaseId]
      evaluationFrequency: 'PT5M'
      windowSize: 'PT5M'
      criteria: {
        'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
        allOf: [
          {
            name: 'SqlCpuAboveThreshold'
            metricNamespace: 'Microsoft.Sql/servers/databases'
            metricName: 'cpu_percent'
            operator: 'GreaterThan'
            threshold: sqlCpuThreshold
            timeAggregation: 'Average'
            criterionType: 'StaticThresholdCriterion'
          }
        ]
      }
      actions: [{ actionGroupId: operationalActionGroupId }]
    }
  }
]

resource sqlConnectionAlerts 'Microsoft.Insights/metricAlerts@2026-01-01' = [
  for (databaseId, index) in sqlDatabaseIds: {
    name: 'alert-${environmentName}-sql-${index + 1}-connections'
    location: 'global'
    properties: {
      description: 'SQL Database connection failures are above the approved threshold.'
      severity: availabilitySeverity
      enabled: enabled
      scopes: [databaseId]
      evaluationFrequency: 'PT5M'
      windowSize: 'PT5M'
      criteria: {
        'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
        allOf: [
          {
            name: 'SqlConnectionsAboveThreshold'
            metricNamespace: 'Microsoft.Sql/servers/databases'
            metricName: 'connection_failed'
            operator: 'GreaterThan'
            threshold: sqlConnectionFailureThreshold
            timeAggregation: 'Total'
            criterionType: 'StaticThresholdCriterion'
          }
        ]
      }
      actions: [{ actionGroupId: operationalActionGroupId }]
    }
  }
]

resource sqlStorageAlerts 'Microsoft.Insights/metricAlerts@2026-01-01' = [
  for (databaseId, index) in sqlDatabaseIds: {
    name: 'alert-${environmentName}-sql-${index + 1}-storage'
    location: 'global'
    properties: {
      description: 'SQL Database storage use is above the approved threshold.'
      severity: performanceSeverity
      enabled: enabled
      scopes: [databaseId]
      evaluationFrequency: 'PT5M'
      windowSize: 'PT5M'
      criteria: {
        'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
        allOf: [
          {
            name: 'SqlStorageAboveThreshold'
            metricNamespace: 'Microsoft.Sql/servers/databases'
            metricName: 'storage_percent'
            operator: 'GreaterThan'
            threshold: sqlStorageThreshold
            timeAggregation: 'Average'
            criterionType: 'StaticThresholdCriterion'
          }
        ]
      }
      actions: [{ actionGroupId: operationalActionGroupId }]
    }
  }
]

resource storageAvailabilityAlerts 'Microsoft.Insights/metricAlerts@2026-01-01' = [
  for (storageAccountId, index) in storageAccountIds: {
    name: 'alert-${environmentName}-storage-${index + 1}-availability'
    location: 'global'
    properties: {
      description: 'Storage account availability is below the approved threshold.'
      severity: availabilitySeverity
      enabled: enabled
      scopes: [storageAccountId]
      evaluationFrequency: 'PT5M'
      windowSize: 'PT5M'
      criteria: {
        'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
        allOf: [
          {
            name: 'StorageAvailabilityBelowThreshold'
            metricNamespace: 'Microsoft.Storage/storageAccounts'
            metricName: 'Availability'
            operator: 'LessThan'
            threshold: storageAvailabilityThreshold
            timeAggregation: 'Average'
            criterionType: 'StaticThresholdCriterion'
          }
        ]
      }
      actions: [{ actionGroupId: operationalActionGroupId }]
    }
  }
]

resource keyVaultAvailabilityAlerts 'Microsoft.Insights/metricAlerts@2026-01-01' = [
  for (keyVaultId, index) in keyVaultIds: {
    name: 'alert-${environmentName}-keyvault-${index + 1}-availability'
    location: 'global'
    properties: {
      description: 'Key Vault availability is below the approved threshold.'
      severity: availabilitySeverity
      enabled: enabled
      scopes: [keyVaultId]
      evaluationFrequency: 'PT5M'
      windowSize: 'PT5M'
      criteria: {
        'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
        allOf: [
          {
            name: 'KeyVaultAvailabilityBelowThreshold'
            metricNamespace: 'Microsoft.KeyVault/vaults'
            metricName: 'Availability'
            operator: 'LessThan'
            threshold: keyVaultAvailabilityThreshold
            timeAggregation: 'Average'
            criterionType: 'StaticThresholdCriterion'
          }
        ]
      }
      actions: [{ actionGroupId: operationalActionGroupId }]
    }
  }
]

resource keyVaultFailureAlerts 'Microsoft.Insights/metricAlerts@2026-01-01' = [
  for (keyVaultId, index) in keyVaultIds: {
    name: 'alert-${environmentName}-keyvault-${index + 1}-failures'
    location: 'global'
    properties: {
      description: 'Key Vault failed API results are above the approved threshold.'
      severity: securitySeverity
      enabled: enabled
      scopes: [keyVaultId]
      evaluationFrequency: 'PT5M'
      windowSize: 'PT5M'
      criteria: {
        'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
        allOf: [
          {
            name: 'KeyVaultFailuresAboveThreshold'
            metricNamespace: 'Microsoft.KeyVault/vaults'
            metricName: 'ServiceApiResult'
            operator: 'GreaterThan'
            threshold: keyVaultFailureThreshold
            timeAggregation: 'Count'
            criterionType: 'StaticThresholdCriterion'
            dimensions: [
              {
                name: 'StatusCodeClass'
                operator: 'Include'
                values: ['4xx', '5xx']
              }
            ]
          }
        ]
      }
      actions: [{ actionGroupId: securityActionGroupId }]
    }
  }
]

output metricAlertCount int = 2 + length(appServicePlanIds) + (2 * length(webAppIds)) + (3 * length(sqlDatabaseIds)) + length(storageAccountIds) + (2 * length(keyVaultIds))
