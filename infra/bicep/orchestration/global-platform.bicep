targetScope = 'resourceGroup'

@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string

@minLength(1)
param wafPolicyName string

@minLength(1)
param frontDoorProfileName string

@minLength(1)
param endpointNamePrefix string

@minLength(1)
param workloads array

param logAnalyticsWorkspaceId string

@minValue(1)
param wafApiRateLimitThreshold int

@minValue(1)
param wafAuthenticationRateLimitThreshold int

param healthProbePath string = '/health/ready'
param enableDiagnostics bool = true
param tags object

module wafPolicyModule '../modules/security/waf-policy.bicep' = {
  name: 'deploy-global-waf-${environmentName}'
  params: {
    wafPolicyName: wafPolicyName
    environmentName: environmentName
    apiRateLimitThreshold: wafApiRateLimitThreshold
    authenticationRateLimitThreshold: wafAuthenticationRateLimitThreshold
    tags: tags
  }
}
module frontDoorModule '../modules/networking/front-door.bicep' = {
  name: 'deploy-global-front-door-${environmentName}'
  params: {
    frontDoorProfileName: frontDoorProfileName
    endpointNamePrefix: endpointNamePrefix
    workloads: workloads
    wafPolicyId: wafPolicyModule.outputs.wafPolicyId
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    healthProbePath: healthProbePath
    enableDiagnostics: enableDiagnostics
    tags: tags
  }
}

output frontDoorProfileId string = frontDoorModule.outputs.frontDoorProfileId
output frontDoorProfileName string = frontDoorModule.outputs.frontDoorProfileName
output frontDoorId string = frontDoorModule.outputs.frontDoorId
output publicEndpoints array = frontDoorModule.outputs.endpointDetails

output wafPolicyId string = wafPolicyModule.outputs.wafPolicyId
output wafPolicyName string = wafPolicyModule.outputs.wafPolicyName
output wafMode string = wafPolicyModule.outputs.wafMode
