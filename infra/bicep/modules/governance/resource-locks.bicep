targetScope = 'resourceGroup'

@description('deployment environment such as dev, test, or prod.')
param environmentName string

@description('control whether CanNotDelete locks are created.')
param enableResourceLocks bool = false

var lockNotes = 'Prevents accidental deletion of a critical ${environmentName} resource. Disable locks before project cleanup.'

@description('Name of the Key Vault to protect.')
param keyVaultName string = ''

@description('Name of the storage account to protect.')
param storageAccountName string = ''

@description('Name of the Azure SQL logical server to protect.')
param sqlServerName string = ''

@description('Name of the Azure Front Door profile to protect. ')
param frontDoorProfileName string = ''

@description('Name of the Log Analytics workspace to protect.')
param logAnalyticsWorkspaceName string = ''

@description('Names of the production App Services to protect.')
param webAppNames array = []

@description('Names of the App Service plans to protect.')
param appServicePlanNames array = []

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = if (keyVaultName != '') {
  name: keyVaultName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' existing = if (storageAccountName != '') {
  name: storageAccountName
}

resource sqlServer 'Microsoft.Sql/servers@2025-01-01' existing = if (sqlServerName != '') {
  name: sqlServerName
}

resource frontDoorProfile 'Microsoft.Cdn/profiles@2024-09-01' existing = if (frontDoorProfileName != '') {
  name: frontDoorProfileName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' existing = if (logAnalyticsWorkspaceName != '') {
  name: logAnalyticsWorkspaceName
}

resource webApps 'Microsoft.Web/sites@2025-03-01' existing = [
  for webAppName in webAppNames: {
    name: webAppName
  }
]

resource appServicePlans 'Microsoft.Web/serverfarms@2025-03-01' existing = [
  for appServicePlanName in appServicePlanNames: {
    name: appServicePlanName
  }
]

resource keyVaultLock 'Microsoft.Authorization/locks@2020-05-01' = if (enableResourceLocks && keyVaultName != '') {
  name: 'lock-cannot-delete'
  scope: keyVault
  properties: {
    level: 'CanNotDelete'
    notes: lockNotes
  }
}

resource storageAccountLock 'Microsoft.Authorization/locks@2020-05-01' = if (enableResourceLocks && storageAccountName != '') {
  name: 'lock-cannot-delete'
  scope: storageAccount
  properties: {
    level: 'CanNotDelete'
    notes: lockNotes
  }
}

resource sqlServerLock 'Microsoft.Authorization/locks@2020-05-01' = if (enableResourceLocks && sqlServerName != '') {
  name: 'lock-cannot-delete'
  scope: sqlServer
  properties: {
    level: 'CanNotDelete'
    notes: lockNotes
  }
}

resource frontDoorProfileLock 'Microsoft.Authorization/locks@2020-05-01' = if (enableResourceLocks && frontDoorProfileName != '') {
  name: 'lock-cannot-delete'
  scope: frontDoorProfile
  properties: {
    level: 'CanNotDelete'
    notes: lockNotes
  }
}

resource logAnalyticsWorkspaceLock 'Microsoft.Authorization/locks@2020-05-01' = if (enableResourceLocks && logAnalyticsWorkspaceName != '') {
  name: 'lock-cannot-delete'
  scope: logAnalyticsWorkspace
  properties: {
    level: 'CanNotDelete'
    notes: lockNotes
  }
}

resource webAppLocks 'Microsoft.Authorization/locks@2020-05-01' = [
  for index in range(0, length(webAppNames)): if (enableResourceLocks) {
    name: 'lock-cannot-delete'
    scope: webApps[index]
    properties: {
      level: 'CanNotDelete'
      notes: lockNotes
    }
  }
]

resource appServicePlanLocks 'Microsoft.Authorization/locks@2020-05-01' = [
  for index in range(0, length(appServicePlanNames)): if (enableResourceLocks) {
    name: 'lock-cannot-delete'
    scope: appServicePlans[index]
    properties: {
      level: 'CanNotDelete'
      notes: lockNotes
    }
  }
]
