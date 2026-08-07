targetScope = 'resourceGroup'

@description('Deployment environment, such as dev, test, or prod.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string

@description('Short project code used in resource names.')
param projectCode string = 'nshop'

@description('Common tags applied to all action groups.')
param tags object

@description('Email receivers for operational alerts.')
param operationalEmailReceivers array = []

@description('Email receivers for security alerts.')
param securityEmailReceivers array = []

@description('Email receivers for cost and budget alerts.')
param costEmailReceivers array = []

var operationalActionGroupName = 'ag-${projectCode}-${environmentName}-operational'
var securityActionGroupName = 'ag-${projectCode}-${environmentName}-security'
var costActionGroupName = 'ag-${projectCode}-${environmentName}-cost'

resource operationalActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: operationalActionGroupName
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'ops-${environmentName}'
    enabled: true
    emailReceivers: [
      for receiver in operationalEmailReceivers: {
        name: receiver.name
        emailAddress: receiver.emailAddress
        useCommonAlertSchema: true
      }
    ]
  }
}

resource securityActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: securityActionGroupName
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'sec-${environmentName}'
    enabled: true
    emailReceivers: [
      for receiver in securityEmailReceivers: {
        name: receiver.name
        emailAddress: receiver.emailAddress
        useCommonAlertSchema: true
      }
    ]
  }
}

resource costActionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: costActionGroupName
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'cost-${environmentName}'
    enabled: true
    emailReceivers: [
      for receiver in costEmailReceivers: {
        name: receiver.name
        emailAddress: receiver.emailAddress
        useCommonAlertSchema: true
      }
    ]
  }
}

output operationalActionGroupId string = operationalActionGroup.id
output securityActionGroupId string = securityActionGroup.id
output costActionGroupId string = costActionGroup.id
