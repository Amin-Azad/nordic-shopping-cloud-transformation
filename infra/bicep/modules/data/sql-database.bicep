targetScope = 'resourceGroup'

param location string
param serverName string

@minLength(1)
@maxLength(128)
param databaseName string

@allowed([
  'GeneralPurpose'
])
param skuTier string = 'GeneralPurpose'

param skuName string
param skuFamily string = 'Gen5'

@minValue(1)
param skuCapacity int

@minValue(1073741824)
param maxSizeBytes int

@allowed([
  'Local'
  'Zone'
  'Geo'
  'GeoZone'
])
param backupStorageRedundancy string = 'Local'

@minValue(1)
@maxValue(35)
param shortTermRetentionDays int = 7

param zoneRedundant bool = false
param tags object

var isServerless = startsWith(skuName, 'GP_S_')

resource sqlServer 'Microsoft.Sql/servers@2025-01-01' existing = {
  name: serverName
}

resource database 'Microsoft.Sql/servers/databases@2025-01-01' = {
  parent: sqlServer
  name: databaseName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
    family: skuFamily
    capacity: skuCapacity
  }
  properties: union(
    {
      collation: 'SQL_Latin1_General_CP1_CI_AS'
      maxSizeBytes: maxSizeBytes
      zoneRedundant: zoneRedundant
      readScale: 'Disabled'
      requestedBackupStorageRedundancy: backupStorageRedundancy
    },
    isServerless
      ? {
          // Geo-replication and failover groups do not support auto-pause.
          autoPauseDelay: -1
          minCapacity: json('0.5')
        }
      : {}
  )
}

resource shortTermRetentionPolicy 'Microsoft.Sql/servers/databases/backupShortTermRetentionPolicies@2025-01-01' = {
  parent: database
  name: 'default'
  properties: {
    retentionDays: shortTermRetentionDays
    diffBackupIntervalInHours: 24
  }
}

output databaseId string = database.id
output databaseName string = database.name
output databaseServerName string = serverName
