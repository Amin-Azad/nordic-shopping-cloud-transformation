param location string
param autoscaleSettingName string
param appServicePlanId string
param autoscaleEnabled bool = true
@minValue(1)
param minimumCapacity int
@minValue(1)
param maximumCapacity int
@minValue(1)
param defaultCapacity int
@minValue(1)
@maxValue(100)
param scaleInCpuThreshold int = 35
param scaleOutCpuThreshold int = 70

resource autoscaleSetting 'Microsoft.Insights/autoscaleSettings@2022-10-01' = {
  name: autoscaleSettingName
  location: location
  properties: {
    enabled: autoscaleEnabled
    targetResourceUri: appServicePlanId
    profiles: [
      {
        name: 'cpu-autoscale-profile'
        capacity: {
          minimum: string(minimumCapacity)
          default: string(defaultCapacity)
          maximum: string(maximumCapacity)
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlanId
              operator: 'GreaterThan'
              statistic: 'Average'
              threshold: scaleOutCpuThreshold
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT20M'
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlanId
              operator: 'LessThan'
              statistic: 'Average'
              threshold: scaleInCpuThreshold
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT20M'
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT10M'
            }
          }
        ]
      }
    ]
  }
}

output autoscaleSettingId string = autoscaleSetting.id
output autoscaleSettingName string = autoscaleSetting.name
