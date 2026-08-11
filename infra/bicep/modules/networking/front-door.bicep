param frontDoorProfileName string
param endpointNamePrefix string
param workloads array
param wafPolicyId string
param logAnalyticsWorkspaceId string
param healthProbePath string = '/health/ready'
param enableDiagnostics bool = true
param tags object

resource frontDoorProfile 'Microsoft.Cdn/profiles@2024-09-01' = {
  name: frontDoorProfileName
  location: 'global'
  tags: tags
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
}

// One endpoint per public workload.
resource frontDoorEndpoints 'Microsoft.Cdn/profiles/afdEndpoints@2024-09-01' = [
  for workload in workloads: {
    parent: frontDoorProfile
    name: '${endpointNamePrefix}-${workload.name}'
    location: 'global'
    tags: tags
    properties: {
      enabledState: 'Enabled'
    }
  }
]

// Each workload has its own health probe and failover configuration.
resource originGroups 'Microsoft.Cdn/profiles/originGroups@2024-09-01' = [
  for workload in workloads: {
    parent: frontDoorProfile
    name: 'og-${workload.name}'
    properties: {
      healthProbeSettings: {
        probePath: healthProbePath
        probeRequestType: 'HEAD'
        probeProtocol: 'Https'
        probeIntervalInSeconds: 30
      }
      loadBalancingSettings: {
        sampleSize: 4
        successfulSamplesRequired: 3
        additionalLatencyInMilliseconds: 0
      }
      sessionAffinityState: 'Disabled'
    }
  }
]

// West Europe is the preferred origin.
resource primaryOrigins 'Microsoft.Cdn/profiles/originGroups/origins@2024-09-01' = [
  for (workload, index) in workloads: {
    parent: originGroups[index]
    name: 'origin-${workload.name}-primary'
    properties: {
      hostName: workload.primaryHostName
      httpPort: 80
      httpsPort: 443
      originHostHeader: workload.primaryHostName
      priority: 1
      weight: 1000
      enabledState: 'Enabled'
      enforceCertificateNameCheck: true
    }
  }
]

// Sweden Central is the DR origin.
resource secondaryOrigins 'Microsoft.Cdn/profiles/originGroups/origins@2024-09-01' = [
  for (workload, index) in workloads: {
    parent: originGroups[index]
    name: 'origin-${workload.name}-secondary'
    properties: {
      hostName: workload.secondaryHostName
      httpPort: 80
      httpsPort: 443
      originHostHeader: workload.secondaryHostName
      priority: 2
      weight: 1000
      enabledState: 'Enabled'
      enforceCertificateNameCheck: true
    }
  }
]

// Each endpoint has one route to its matching origin group.
resource routes 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-09-01' = [
  for (workload, index) in workloads: {
    parent: frontDoorEndpoints[index]
    name: 'route-${workload.name}'
    properties: {
      originGroup: {
        id: originGroups[index].id
      }
      supportedProtocols: [
        'Http'
        'Https'
      ]
      patternsToMatch: [
        '/*'
      ]
      forwardingProtocol: 'HttpsOnly'
      linkToDefaultDomain: 'Enabled'
      httpsRedirect: 'Enabled'
      enabledState: 'Enabled'
      cacheConfiguration: null
    }
    dependsOn: [
      primaryOrigins
      secondaryOrigins
    ]
  }
]

// Associate the WAF policy with every Front Door endpoint.
resource securityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2024-09-01' = {
  parent: frontDoorProfile
  name: 'security-policy-${frontDoorProfileName}'
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      wafPolicy: {
        id: wafPolicyId
      }
      associations: [
        {
          domains: [
            for (workload, index) in workloads: {
              id: frontDoorEndpoints[index].id
            }
          ]
          patternsToMatch: [
            '/*'
          ]
        }
      ]
    }
  }
  dependsOn: [
    routes
  ]
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableDiagnostics) {
  name: 'diag-${frontDoorProfileName}'
  scope: frontDoorProfile
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'FrontDoorAccessLog'
        enabled: true
      }
      {
        category: 'FrontDoorHealthProbeLog'
        enabled: true
      }
      {
        category: 'FrontDoorWebApplicationFirewallLog'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output frontDoorProfileId string = frontDoorProfile.id
output frontDoorProfileName string = frontDoorProfile.name

// This value is required later for the X-Azure-FDID origin restriction.
output frontDoorId string = frontDoorProfile.properties.frontDoorId

output endpointDetails array = [
  for (workload, index) in workloads: {
    workload: workload.name
    endpointId: frontDoorEndpoints[index].id
    endpointName: frontDoorEndpoints[index].name
    endpointHostname: frontDoorEndpoints[index].properties.hostName
    primaryOriginHostname: workload.primaryHostName
    secondaryOriginHostname: workload.secondaryHostName
  }
]
