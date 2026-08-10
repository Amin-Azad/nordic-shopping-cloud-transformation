targetScope = 'resourceGroup'
@minLength(1)
@maxLength(63)
param failoverGroupName string
param primaryServerName string
param primaryDatabaseId string
param secondaryServerId string

//Minutes Azure waits before attempting automatic failover with possible data loss.
@minValue(60)
param failoverGracePeriodMinutes int = 60

param tags object

resource primarySqlServer 'Microsoft.Sql/servers@2025-01-01' existing = {
  name: primaryServerName
}

resource sqlFailoverGroup 'Microsoft.Sql/servers/failoverGroups@2025-01-01' = {
  parent: primarySqlServer
  name: failoverGroupName
  tags: tags
  properties: {
    databases: [
      primaryDatabaseId
    ]
    partnerServers: [
      {
        id: secondaryServerId
      }
    ]
    readWriteEndpoint: {
      failoverPolicy: 'Automatic'
      failoverWithDataLossGracePeriodMinutes: failoverGracePeriodMinutes
    }
    readOnlyEndpoint: {
      failoverPolicy: 'Disabled'
    }
    secondaryType: 'Geo'
  }
}

output failoverGroupId string = sqlFailoverGroup.id
output failoverGroupName string = sqlFailoverGroup.name
output readWriteListener string = '${failoverGroupName}${environment().suffixes.sqlServerHostname}'
output readOnlyListener string = '${failoverGroupName}.secondary${environment().suffixes.sqlServerHostname}'
