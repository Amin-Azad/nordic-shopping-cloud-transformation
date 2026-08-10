targetScope = 'resourceGroup'

param location string

@description('Globally unique SQL logical server name.')
@minLength(1)
@maxLength(63)
param serverName string

//Microsoft Entra administrator name.
param entraAdminLogin string
//Object ID of the Microsoft Entra administrator
param entraAdminObjectId string
//Tenant ID.
param entraAdminTenantId string
param logAnalyticsWorkspaceId string
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'
param enableAdvancedThreatProtection bool = false
param tags object

resource sqlServer 'Microsoft.Sql/servers@2025-01-01' = {
  name: serverName
  location: location
  tags: tags
  properties: {
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: publicNetworkAccess
    restrictOutboundNetworkAccess: 'Disabled'
  }
}

resource entraAdministrator 'Microsoft.Sql/servers/administrators@2025-01-01' = {
  parent: sqlServer
  name: 'ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: entraAdminLogin
    sid: entraAdminObjectId
    tenantId: entraAdminTenantId
  }
}
resource entraOnlyAuthentication 'Microsoft.Sql/servers/azureADOnlyAuthentications@2025-01-01' = {
  parent: sqlServer
  name: 'Default'
  properties: {
    azureADOnlyAuthentication: true
  }
  dependsOn: [
    entraAdministrator
  ]
}

resource sqlAuditing 'Microsoft.Sql/servers/extendedAuditingSettings@2025-01-01' = {
  parent: sqlServer
  name: 'default'
  properties: {
    state: 'Enabled'
    isAzureMonitorTargetEnabled: true
    retentionDays: 0
  }
}

resource advancedThreatProtection 'Microsoft.Sql/servers/advancedThreatProtectionSettings@2025-01-01' = {
  parent: sqlServer
  name: 'Default'
  properties: {
    state: enableAdvancedThreatProtection ? 'Enabled' : 'Disabled'
  }
}

resource masterDatabase 'Microsoft.Sql/servers/databases@2025-01-01' existing = {
  parent: sqlServer
  name: 'master'
}

#disable-next-line use-recent-api-versions
resource masterDatabaseDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${serverName}-diagnostics'
  scope: masterDatabase
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'SQLSecurityAuditEvents'
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
  dependsOn: [
    sqlAuditing
  ]
}

output sqlServerId string = sqlServer.id
output sqlServerName string = sqlServer.name
output fullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName
