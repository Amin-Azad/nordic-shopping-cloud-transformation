param location string
param workbookName string
param displayName string
param environmentName string
param applicationInsightsId string
param logAnalyticsWorkspaceId string
param frontDoorProfileId string
param appServicePlanIds array
param primaryWebAppIds array
param secondaryWebAppIds array
param sqlDatabaseIds array
param primaryLocation string
param secondaryLocation string
param tags object

var workbookSourceId = applicationInsightsId
var allWebAppIds = concat(primaryWebAppIds, secondaryWebAppIds)

var workbookContent = {
  version: 'Notebook/1.0'
  items: [
    {
      type: 1
      content: {
        json: '# Nordic Shopping - ${toUpper(environmentName)} operations dashboard\nUse the time selector to investigate traffic, availability, application failures, platform capacity, database health, active alerts, and regional status.'
      }
      name: 'workbook-title'
    }
    {
      type: 9
      content: {
        version: 'KqlParameterItem/1.0'
        parameters: [
          {
            id: 'time-range'
            version: 'KqlParameterItem/1.0'
            name: 'TimeRange'
            type: 4
            isRequired: true
            value: {
              durationMs: 86400000
            }
            typeSettings: {
              selectableValues: [
                { durationMs: 3600000 }
                { durationMs: 14400000 }
                { durationMs: 43200000 }
                { durationMs: 86400000 }
                { durationMs: 259200000 }
                { durationMs: 604800000 }
              ]
              allowCustom: true
            }
            label: 'Time range'
          }
        ]
        style: 'pills'
        queryType: 0
        resourceType: 'microsoft.insights/components'
      }
      name: 'time-parameters'
    }
    {
      type: 1
      content: {
        json: '## Application traffic and reliability'
      }
      name: 'application-heading'
    }
    {
      type: 3
      content: {
        version: 'KqlItem/1.0'
        query: 'requests\n| summarize Requests=count(), Successful=countif(success == true), Failed=countif(success == false), Availability=round(100.0 * countif(success == true) / count(), 2), AvgResponseMs=round(avg(duration), 1), P95ResponseMs=round(percentile(duration, 95), 1)'
        size: 4
        title: 'Request count, success rate and response time'
        timeContext: {
          durationMs: 0
        }
        timeContextFromParameter: 'TimeRange'
        queryType: 0
        resourceType: 'microsoft.insights/components'
        resource: applicationInsightsId
        visualization: 'tiles'
        tileSettings: {
          titleContent: {
            columnMatch: 'ColumnName'
            formatter: 1
          }
          leftContent: {
            columnMatch: 'ColumnValue'
            formatter: 12
          }
          showBorder: true
        }
      }
      name: 'application-kpis'
    }
    {
      type: 3
      content: {
        version: 'KqlItem/1.0'
        query: 'requests\n| summarize Requests=count(), Failures=countif(success == false), P95ResponseMs=percentile(duration, 95) by bin(timestamp, 5m)\n| order by timestamp asc'
        size: 0
        title: 'Request volume, failures and P95 latency'
        timeContextFromParameter: 'TimeRange'
        queryType: 0
        resourceType: 'microsoft.insights/components'
        resource: applicationInsightsId
        visualization: 'timechart'
      }
      name: 'request-trend'
    }
    {
      type: 3
      content: {
        version: 'KqlItem/1.0'
        query: 'requests\n| where resultCode startswith "5"\n| summarize Http5xx=count() by resultCode, operation_Name\n| order by Http5xx desc\n| take 20'
        size: 0
        title: 'HTTP 5xx errors by operation'
        timeContextFromParameter: 'TimeRange'
        queryType: 0
        resourceType: 'microsoft.insights/components'
        resource: applicationInsightsId
        visualization: 'table'
      }
      name: 'http-5xx'
    }
    {
      type: 3
      content: {
        version: 'KqlItem/1.0'
        query: 'exceptions\n| summarize Exceptions=count(), AffectedUsers=dcount(user_Id) by type, outerMessage\n| order by Exceptions desc\n| take 20'
        size: 0
        title: 'Top application exceptions'
        timeContextFromParameter: 'TimeRange'
        queryType: 0
        resourceType: 'microsoft.insights/components'
        resource: applicationInsightsId
        visualization: 'table'
      }
      name: 'exceptions'
    }
    {
      type: 3
      content: {
        version: 'KqlItem/1.0'
        query: 'dependencies\n| summarize Calls=count(), Failures=countif(success == false), P95DurationMs=round(percentile(duration, 95), 1) by target, type\n| order by Failures desc, P95DurationMs desc\n| take 20'
        size: 0
        title: 'Dependency calls, failures and latency'
        timeContextFromParameter: 'TimeRange'
        queryType: 0
        resourceType: 'microsoft.insights/components'
        resource: applicationInsightsId
        visualization: 'table'
      }
      name: 'dependencies'
    }
    {
      type: 1
      content: {
        json: '## Front Door traffic and origin health'
      }
      name: 'front-door-heading'
    }
    {
      type: 10
      content: {
        version: 'MetricsItem/2.0'
        size: 0
        title: 'Front Door requests, 5xx responses and origin health'
        chartId: '0'
        timeContextFromParameter: 'TimeRange'
        resourceType: 'microsoft.cdn/profiles'
        resourceIds: [frontDoorProfileId]
        metrics: [
          {
            namespace: 'microsoft.cdn/profiles'
            metric: 'RequestCount'
            aggregation: 1
          }
          {
            namespace: 'microsoft.cdn/profiles'
            metric: 'Percentage5XX'
            aggregation: 4
          }
          {
            namespace: 'microsoft.cdn/profiles'
            metric: 'OriginHealthPercentage'
            aggregation: 4
          }
          {
            namespace: 'microsoft.cdn/profiles'
            metric: 'OriginLatency'
            aggregation: 4
          }
        ]
      }
      name: 'front-door-metrics'
    }
    {
      type: 3
      content: {
        version: 'KqlItem/1.0'
        query: 'AzureDiagnostics\n| where Category == "FrontDoorAccessLog"\n| summarize Requests=count(), Http4xx=countif(toint(httpStatusCode_s) between (400 .. 499)), Http5xx=countif(toint(httpStatusCode_s) >= 500), AvgLatencyMs=round(avg(todouble(timeTaken_d)) * 1000.0, 1) by requestUri_s\n| order by Requests desc\n| take 20'
        size: 0
        title: 'Front Door busiest paths and failures'
        timeContextFromParameter: 'TimeRange'
        queryType: 0
        resourceType: 'microsoft.operationalinsights/workspaces'
        resource: logAnalyticsWorkspaceId
        visualization: 'table'
      }
      name: 'front-door-paths'
    }
    {
      type: 1
      content: {
        json: '## App Service capacity'
      }
      name: 'app-service-heading'
    }
    {
      type: 10
      content: {
        version: 'MetricsItem/2.0'
        size: 0
        title: 'Plan CPU, memory and worker count - both regions'
        chartId: '0'
        timeContextFromParameter: 'TimeRange'
        resourceType: 'microsoft.web/serverfarms'
        resourceIds: appServicePlanIds
        metrics: [
          {
            namespace: 'microsoft.web/serverfarms'
            metric: 'CpuPercentage'
            aggregation: 4
          }
          {
            namespace: 'microsoft.web/serverfarms'
            metric: 'MemoryPercentage'
            aggregation: 4
          }
          {
            namespace: 'microsoft.web/serverfarms'
            metric: 'InstanceCount'
            aggregation: 4
          }
        ]
      }
      name: 'app-service-plan-metrics'
    }
    {
      type: 10
      content: {
        version: 'MetricsItem/2.0'
        size: 0
        title: 'Web App requests, 5xx, response time, connections and health'
        chartId: '0'
        timeContextFromParameter: 'TimeRange'
        resourceType: 'microsoft.web/sites'
        resourceIds: allWebAppIds
        metrics: [
          {
            namespace: 'microsoft.web/sites'
            metric: 'Requests'
            aggregation: 1
          }
          {
            namespace: 'microsoft.web/sites'
            metric: 'Http5xx'
            aggregation: 1
          }
          {
            namespace: 'microsoft.web/sites'
            metric: 'AverageResponseTime'
            aggregation: 4
          }
          {
            namespace: 'microsoft.web/sites'
            metric: 'AppConnections'
            aggregation: 4
          }
          {
            namespace: 'microsoft.web/sites'
            metric: 'HealthCheckStatus'
            aggregation: 4
          }
          {
            namespace: 'microsoft.web/sites'
            metric: 'MemoryWorkingSet'
            aggregation: 4
          }
        ]
      }
      name: 'web-app-metrics'
    }
    {
      type: 1
      content: {
        json: '## SQL database health'
      }
      name: 'sql-heading'
    }
    {
      type: 10
      content: {
        version: 'MetricsItem/2.0'
        size: 0
        title: 'SQL CPU, data IO, log IO, storage and connections'
        chartId: '0'
        timeContextFromParameter: 'TimeRange'
        resourceType: 'microsoft.sql/servers/databases'
        resourceIds: sqlDatabaseIds
        metrics: [
          {
            namespace: 'microsoft.sql/servers/databases'
            metric: 'cpu_percent'
            aggregation: 4
          }
          {
            namespace: 'microsoft.sql/servers/databases'
            metric: 'physical_data_read_percent'
            aggregation: 4
          }
          {
            namespace: 'microsoft.sql/servers/databases'
            metric: 'log_write_percent'
            aggregation: 4
          }
          {
            namespace: 'microsoft.sql/servers/databases'
            metric: 'storage_percent'
            aggregation: 4
          }
          {
            namespace: 'microsoft.sql/servers/databases'
            metric: 'connection_successful'
            aggregation: 1
          }
          {
            namespace: 'microsoft.sql/servers/databases'
            metric: 'connection_failed'
            aggregation: 1
          }
          {
            namespace: 'microsoft.sql/servers/databases'
            metric: 'deadlock'
            aggregation: 1
          }
        ]
      }
      name: 'sql-metrics'
    }
    {
      type: 1
      content: {
        json: '## Alerts and platform health'
      }
      name: 'alerts-heading'
    }
    {
      type: 3
      content: {
        version: 'KqlItem/1.0'
        query: 'alertsmanagementresources\n| where type =~ "microsoft.alertsmanagement/alerts"\n| extend state=tostring(properties.essentials.monitorCondition), severity=tostring(properties.essentials.severity), signal=tostring(properties.essentials.signalType), target=tostring(properties.essentials.targetResource)\n| where state =~ "Fired"\n| project severity, signal, alertName=name, target, firedTime=todatetime(properties.essentials.startDateTime)\n| order by severity asc, firedTime desc'
        size: 0
        title: 'Active metric, log and Activity Log alerts'
        queryType: 1
        resourceType: 'microsoft.resourcegraph/resources'
        subscriptions: [subscription().subscriptionId]
        visualization: 'table'
      }
      name: 'active-alerts'
    }
    {
      type: 3
      content: {
        version: 'KqlItem/1.0'
        query: 'servicehealthresources\n| extend eventType=tostring(properties.EventType), status=tostring(properties.Status), trackingId=tostring(properties.TrackingId), startTime=todatetime(properties.ImpactStartTime), lastUpdate=todatetime(properties.LastUpdateTime), summary=tostring(properties.Summary)\n| project eventType, status, trackingId, startTime, lastUpdate, location, summary\n| order by lastUpdate desc\n| take 100'
        size: 0
        title: 'Service Health events'
        queryType: 1
        resourceType: 'microsoft.resourcegraph/resources'
        subscriptions: [subscription().subscriptionId]
        visualization: 'table'
      }
      name: 'service-health-events'
    }
    {
      type: 3
      content: {
        version: 'KqlItem/1.0'
        query: 'healthresources\n| where type =~ "microsoft.resourcehealth/availabilitystatuses"\n| extend availabilityState=tostring(properties.availabilityState), previousState=tostring(properties.previousAvailabilityState), occurredTime=todatetime(properties.occurredTime), reasonType=tostring(properties.reasonType), summary=tostring(properties.summary)\n| project resourceId=tolower(substring(id, 0, indexof(id, "/providers/Microsoft.ResourceHealth"))), availabilityState, previousState, occurredTime, reasonType, summary\n| order by occurredTime desc'
        size: 0
        title: 'Current Resource Health status'
        queryType: 1
        resourceType: 'microsoft.resourcegraph/resources'
        subscriptions: [subscription().subscriptionId]
        visualization: 'table'
      }
      name: 'resource-health-status'
    }
    {
      type: 1
      content: {
        json: '## Primary versus secondary region\nPrimary: **${primaryLocation}** · Secondary: **${secondaryLocation}**'
      }
      name: 'regional-heading'
    }
    {
      type: 3
      content: {
        version: 'KqlItem/1.0'
        query: 'resources\n| where tostring(tags.environment) =~ "${environmentName}"\n| where location =~ "${primaryLocation}" or location =~ "${secondaryLocation}"\n| where type in~ ("microsoft.web/sites", "microsoft.web/serverfarms", "microsoft.sql/servers", "microsoft.sql/servers/databases")\n| extend RegionRole=case(location =~ "${primaryLocation}", "Primary", location =~ "${secondaryLocation}", "Secondary", "Other")\n| project RegionRole, location, resourceType=type, resourceName=name, provisioningState=tostring(properties.provisioningState), state=tostring(properties.state)\n| order by RegionRole asc, resourceType asc, resourceName asc'
        size: 0
        title: 'Regional resource and provisioning status'
        queryType: 1
        resourceType: 'microsoft.resourcegraph/resources'
        subscriptions: [subscription().subscriptionId]
        visualization: 'table'
      }
      name: 'regional-status'
    }
  ]
  fallbackResourceIds: [workbookSourceId]
}

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: workbookName
  location: location
  kind: 'shared'
  tags: tags
  properties: {
    displayName: displayName
    serializedData: string(workbookContent)
    version: '1.0'
    sourceId: workbookSourceId
    category: 'workbook'
  }
}

output workbookId string = workbook.id
output deployedWorkbookName string = workbook.name
output workbookDisplayName string = workbook.properties.displayName
