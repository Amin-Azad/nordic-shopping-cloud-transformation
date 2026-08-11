targetScope = 'resourceGroup'

@description('Names of the Web Apps to protect.')
param webAppNames array

@description('Azure Front Door profile ID used in the X-Azure-FDID header.')
param frontDoorId string

resource webApps 'Microsoft.Web/sites@2024-11-01' existing = [
  for webAppName in webAppNames: {
    name: webAppName
  }
]

resource webAppAccessRestrictions 'Microsoft.Web/sites/config@2024-11-01' = [
  for (webAppName, index) in webAppNames: {
    parent: webApps[index]
    name: 'web'
    properties: {
      ipSecurityRestrictionsDefaultAction: 'Deny'
      ipSecurityRestrictions: [
        {
          name: 'Allow-Azure-Front-Door'
          description: 'Allow traffic from the approved Azure Front Door profile.'
          action: 'Allow'
          priority: 100
          ipAddress: 'AzureFrontDoor.Backend'
          tag: 'ServiceTag'
          headers: {
            'x-azure-fdid': [
              frontDoorId
            ]
          }
        }
      ]
    }
  }
]

output protectedWebAppNames array = webAppNames
