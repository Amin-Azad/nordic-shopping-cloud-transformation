param environmentName string
param location string
param logAnalyticsWorkspaceId string
param operationalActionGroupId string
param securityActionGroupId string
param tags object

param enableLogAlerts bool = false
param enableAdministrativeOperationAlert bool = false

param applicationExceptionThreshold int = 5
param authenticationFailureThreshold int = 10
param privateAccessViolationThreshold int = 1
param administrativeOperationThreshold int = 1

@allowed([0, 1, 2, 3, 4])
param operationalSeverity int = 2

@allowed([0, 1, 2, 3, 4])
param securitySeverity int = 1

resource applicationExceptionAlert 'Microsoft.Insights/scheduledQueryRules@2026-03-01' = if (enableLogAlerts) {
  name: 'alert-${environmentName}-application-exceptions'
  location: location
  kind: 'LogAlert'
  tags: tags
  properties: {
    displayName: 'Application exception pattern'
    description: 'Application exceptions exceeded the approved threshold.'
    severity: operationalSeverity
    enabled: true
    scopes: [
      logAnalyticsWorkspaceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    skipQueryValidation: true
    autoMitigate: true
    criteria: {
      allOf: [
        {
          query: '''
            AppExceptions
            | summarize ExceptionCount = count()
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThanOrEqual'
          threshold: applicationExceptionThreshold
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        operationalActionGroupId
      ]
    }
  }
}

resource authenticationFailureAlert 'Microsoft.Insights/scheduledQueryRules@2026-03-01' = if (enableLogAlerts) {
  name: 'alert-${environmentName}-authentication-failures'
  location: location
  kind: 'LogAlert'
  tags: tags
  properties: {
    displayName: 'Repeated authentication failures'
    description: 'Repeated HTTP 401 or 403 responses were detected in App Service logs.'
    severity: securitySeverity
    enabled: true
    scopes: [
      logAnalyticsWorkspaceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    skipQueryValidation: true
    autoMitigate: true
    criteria: {
      allOf: [
        {
          query: '''
            AzureDiagnostics
            | where ResourceProvider == "MICROSOFT.WEB"
            | extend StatusCode = toint(column_ifexists("httpStatusCode_d", 0))
            | where StatusCode in (401, 403)
            | summarize FailureCount = count()
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThanOrEqual'
          threshold: authenticationFailureThreshold
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        securityActionGroupId
      ]
    }
  }
}

resource privateAccessViolationAlert 'Microsoft.Insights/scheduledQueryRules@2026-03-01' = if (enableLogAlerts) {
  name: 'alert-${environmentName}-private-access-violations'
  location: location
  kind: 'LogAlert'
  tags: tags
  properties: {
    displayName: 'Private-access violation'
    description: 'A denied request was detected against a protected Storage, Key Vault, SQL, or AI resource.'
    severity: securitySeverity
    enabled: true
    scopes: [
      logAnalyticsWorkspaceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    skipQueryValidation: true
    autoMitigate: true
    criteria: {
      allOf: [
        {
          query: '''
            union isfuzzy=true
            (
              StorageBlobLogs
              | extend StatusCodeValue = toint(StatusCode)
              | where StatusCodeValue == 403
              | project TimeGenerated, ResourceId = _ResourceId
            ),
            (
              AzureDiagnostics
              | where ResourceProvider in (
                  "MICROSOFT.KEYVAULT",
                  "MICROSOFT.SQL",
                  "MICROSOFT.COGNITIVESERVICES"
                )
              | extend StatusCodeValue = toint(column_ifexists("httpStatusCode_d", 0))
              | extend ResultValue = tostring(column_ifexists("ResultType", ""))
              | where StatusCodeValue == 403
                  or ResultValue in~ ("Forbidden", "Unauthorized")
              | project TimeGenerated, ResourceId = _ResourceId
            )
            | summarize ViolationCount = count()
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThanOrEqual'
          threshold: privateAccessViolationThreshold
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        securityActionGroupId
      ]
    }
  }
}

resource administrativeOperationAlert 'Microsoft.Insights/scheduledQueryRules@2026-03-01' = if (enableLogAlerts && enableAdministrativeOperationAlert) {
  name: 'alert-${environmentName}-administrative-operations'
  location: location
  kind: 'LogAlert'
  tags: tags
  properties: {
    displayName: 'High-impact administrative operation'
    description: 'A successful high-impact administrative operation was detected.'
    severity: securitySeverity
    enabled: true
    scopes: [
      logAnalyticsWorkspaceId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    skipQueryValidation: true
    autoMitigate: true
    criteria: {
      allOf: [
        {
          query: '''
            AzureActivity
            | where ActivityStatusValue =~ "Succeeded"
            | where OperationNameValue has_any (
                "Microsoft.Authorization/roleAssignments/write",
                "Microsoft.Authorization/roleAssignments/delete",
                "Microsoft.Authorization/policyAssignments/write",
                "Microsoft.Authorization/policyAssignments/delete",
                "Microsoft.Authorization/locks/delete"
              )
            | summarize AdministrativeOperationCount = count()
          '''
          timeAggregation: 'Count'
          operator: 'GreaterThanOrEqual'
          threshold: administrativeOperationThreshold
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [
        securityActionGroupId
      ]
    }
  }
}

output applicationExceptionAlertId string = enableLogAlerts ? applicationExceptionAlert.id : ''

output authenticationFailureAlertId string = enableLogAlerts ? authenticationFailureAlert.id : ''

output privateAccessViolationAlertId string = enableLogAlerts ? privateAccessViolationAlert.id : ''

output administrativeOperationAlertId string = enableLogAlerts && enableAdministrativeOperationAlert
  ? administrativeOperationAlert.id
  : ''
