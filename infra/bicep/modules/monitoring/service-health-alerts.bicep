param environmentName string
param operationalActionGroupId string
param securityActionGroupId string
param tags object
param enabled bool = true

var subscriptionScope = subscription().id

resource serviceHealthAlert 'Microsoft.Insights/activityLogAlerts@2026-01-01' = {
  name: 'alert-${environmentName}-service-health'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alerts when Azure publishes a Service Health notification.'
    enabled: enabled
    scopes: [
      subscriptionScope
    ]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'ServiceHealth'
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: operationalActionGroupId
        }
      ]
    }
  }
}

resource resourceHealthAlert 'Microsoft.Insights/activityLogAlerts@2026-01-01' = {
  name: 'alert-${environmentName}-resource-health'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alerts when an Azure resource becomes unavailable, degraded, or unknown.'
    enabled: enabled
    scopes: [
      subscriptionScope
    ]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'ResourceHealth'
        }
        {
          field: 'properties.currentHealthStatus'
          containsAny: [
            'Unavailable'
            'Degraded'
            'Unknown'
          ]
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: operationalActionGroupId
        }
      ]
    }
  }
}

resource administrativeChangesAlert 'Microsoft.Insights/activityLogAlerts@2026-01-01' = {
  name: 'alert-${environmentName}-high-impact-changes'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alerts on successful high-impact security and governance changes.'
    enabled: enabled
    scopes: [
      subscriptionScope
    ]
    condition: {
      allOf: [
        {
          field: 'category'
          equals: 'Administrative'
        }
        {
          field: 'status'
          equals: 'Succeeded'
        }
        {
          anyOf: [
            {
              field: 'operationName'
              equals: 'Microsoft.Authorization/roleAssignments/write'
            }
            {
              field: 'operationName'
              equals: 'Microsoft.Authorization/roleAssignments/delete'
            }
            {
              field: 'operationName'
              equals: 'Microsoft.Authorization/policyAssignments/write'
            }
            {
              field: 'operationName'
              equals: 'Microsoft.Authorization/policyAssignments/delete'
            }
            {
              field: 'operationName'
              equals: 'Microsoft.Authorization/locks/write'
            }
            {
              field: 'operationName'
              equals: 'Microsoft.Authorization/locks/delete'
            }
            {
              field: 'operationName'
              equals: 'Microsoft.Insights/actionGroups/write'
            }
            {
              field: 'operationName'
              equals: 'Microsoft.Insights/actionGroups/delete'
            }
          ]
        }
      ]
    }
    actions: {
      actionGroups: [
        {
          actionGroupId: securityActionGroupId
        }
      ]
    }
  }
}
