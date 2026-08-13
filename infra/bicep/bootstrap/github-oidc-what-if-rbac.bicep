targetScope = 'subscription'

@description('Object ID of the GitHub Actions OIDC service principal.')
param servicePrincipalObjectId string

var roleName = 'Nordic Shopping What-If Reader'

resource whatIfRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: '93097265-5223-4563-bbc6-14a9eddfa789'
  properties: {
    roleName: roleName
    description: 'Read-only access plus ARM deployment validation and What-If operations.'
    type: 'CustomRole'
    permissions: [
      {
        actions: [
          '*/read'
          'Microsoft.Resources/deployments/validate/action'
          'Microsoft.Resources/deployments/whatIf/action'
        ]
        notActions: []
        dataActions: []
        notDataActions: []
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}

resource whatIfRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, servicePrincipalObjectId, whatIfRoleDefinition.id)
  properties: {
    principalId: servicePrincipalObjectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: whatIfRoleDefinition.id
  }
}

output customRoleDefinitionId string = whatIfRoleDefinition.id
output roleAssignmentId string = whatIfRoleAssignment.id
