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

@allowed([
  'Default'
  'Secondary'
])
param createMode string = 'Default'

@description('Resource ID of the primary database when createMode is Secondary.')
param sourceDatabaseId string = ''

@description('''
Auto-pause delay in minutes for serverless SKUs. -1 disables auto-pause, which is
required when the database participates in a geo-replication or failover group.
Azure's minimum positive value is 60. A paused database costs storage only.
''')
param autoPauseDelayMinutes int = -1

param tags object

var isServerless = startsWith(skuName, 'GP_S_')
var isSecondary = createMode == 'Secondary'

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
          // -1 disables auto-pause. Required for failover groups, which do not
          // support it. Single-region databases can and should pause.
          autoPauseDelay: autoPauseDelayMinutes
          minCapacity: json('0.5')
        }
      : {},
    isSecondary
      ? {
          createMode: 'Secondary'
          sourceDatabaseId: sourceDatabaseId
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
