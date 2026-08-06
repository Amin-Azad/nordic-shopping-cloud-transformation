targetScope = 'subscription'

@description('name of the monthly budget')
param budgetName string

@description('maximum')
@minValue(1)
param budgetAmount int

@description('budget start sate ISO 8601 format')
param startDate string

@description('budget end date')
param endDate string

@description('Email Address for notification')
@secure()
param contactEmail string

@description('optional Action group redource id for notification')
param actionGroupIds array = []

resource monthlyBudget 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: budgetName
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
      endDate: endDate
    }
    notifications: {
      Actual50Percent: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 50
        thresholdType: 'Actual'
        contactEmails: [contactEmail]
        contactGroups: actionGroupIds
      }
      Actual70Percent: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 70
        thresholdType: 'Actual'
        contactEmails: [contactEmail]
        contactGroups: actionGroupIds
      }
      Actual85Percent: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 85
        thresholdType: 'Actual'
        contactEmails: [contactEmail]
        contactGroups: actionGroupIds
      }
      Forecast90Percent: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 90
        thresholdType: 'Forecasted'
        contactEmails: [contactEmail]
        contactGroups: actionGroupIds
      }
      Actual100Percent: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        thresholdType: 'Actual'
        contactEmails: [contactEmail]
        contactGroups: actionGroupIds
      }
    }
  }
}
@description('Outputs the budget resource id')
output budgetId string = monthlyBudget.id

@description('Name of the deployed Azure budget')
output deployedBudgetName string = monthlyBudget.name
