@minLength(1)
@maxLength(128)
param wafPolicyName string

@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string

//Maximum API requests allowed per client IP per minute.
@minValue(1)
param apiRateLimitThreshold int

//Maximum authentication requests allowed per client IP per five minutes.
@minValue(1)
param authenticationRateLimitThreshold int
param tags object

var wafMode = environmentName == 'prod' ? 'Prevention' : 'Detection'

resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2025-03-01' = {
  name: wafPolicyName
  location: 'Global'
  tags: tags
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: wafMode
    }
    customRules: {
      rules: [
        {
          name: 'BlockUnsupportedMethods'
          priority: 120
          enabledState: 'Enabled'
          ruleType: 'MatchRule'
          action: 'Block'
          matchConditions: [
            {
              matchVariable: 'RequestMethod'
              operator: 'Equal'
              matchValue: [
                'TRACE'
                'TRACK'
              ]
              transforms: [
                'Uppercase'
              ]
              negateCondition: false
            }
          ]
        }
        {
          name: 'RateLimitApi'
          priority: 200
          enabledState: 'Enabled'
          ruleType: 'RateLimitRule'
          action: 'Block'
          rateLimitThreshold: apiRateLimitThreshold
          rateLimitDurationInMinutes: 1
          groupBy: [
            {
              variableName: 'SocketAddr'
            }
          ]
          matchConditions: [
            {
              matchVariable: 'RequestUri'
              operator: 'BeginsWith'
              matchValue: [
                '/api/'
              ]
              transforms: [
                'Lowercase'
              ]
              negateCondition: false
            }
          ]
        }
        {
          name: 'RateLimitAuthentication'
          priority: 210
          enabledState: 'Enabled'
          ruleType: 'RateLimitRule'
          action: 'Block'
          rateLimitThreshold: authenticationRateLimitThreshold
          rateLimitDurationInMinutes: 5
          groupBy: [
            {
              variableName: 'SocketAddr'
            }
          ]
          matchConditions: [
            {
              matchVariable: 'RequestUri'
              operator: 'Contains'
              matchValue: [
                '/api/auth'
              ]
              transforms: [
                'Lowercase'
              ]
              negateCondition: false
            }
          ]
        }
      ]
    }
  }
}

output wafPolicyId string = wafPolicy.id
output wafPolicyName string = wafPolicy.name
output wafMode string = wafMode
