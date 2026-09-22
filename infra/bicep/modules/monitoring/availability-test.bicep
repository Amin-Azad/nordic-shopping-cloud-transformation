targetScope = 'resourceGroup'

@description('Region for the web test resource. Must match the Application Insights region.')
param location string

@description('Name of the availability test.')
param webTestName string

@description('Resource ID of the Application Insights component that owns this test.')
param applicationInsightsId string

@description('Absolute URL probed by the availability test.')
param testUrl string

@description('Probe interval in seconds.')
@allowed([
  300
  600
  900
])
param frequencySeconds int = 300

@description('Azure test agent locations that run the probe.')
param testLocations array = [
  'emea-nl-ams-azr'
  'emea-se-sto-edge'
  'emea-gb-db3-azr'
]

@description('Action group notified when the availability test fails.')
param actionGroupId string

@description('Number of test locations that must fail before the alert fires.')
param failedLocationThreshold int = 2

@allowed([0, 1, 2, 3, 4])
param alertSeverity int = 1

param enableAlert bool = true

param tags object

resource availabilityTest 'Microsoft.Insights/webtests@2022-06-15' = {
  name: webTestName
  location: location
  tags: union(tags, {
    'hidden-link:${applicationInsightsId}': 'Resource'
  })
  kind: 'standard'
  properties: {
    SyntheticMonitorId: webTestName
    Name: webTestName
    Description: 'Confirms the deployed application reports readiness from multiple regions.'
    Enabled: true
    Frequency: frequencySeconds
    Timeout: 30
    Kind: 'standard'
    RetryEnabled: true
    Locations: [
      for testLocation in testLocations: {
        Id: testLocation
      }
    ]
    Request: {
      RequestUrl: testUrl
      HttpVerb: 'GET'
      ParseDependentRequests: false
      FollowRedirects: false
    }
    ValidationRules: {
      ExpectedHttpStatusCode: 200
      IgnoreHttpStatusCode: false
      SSLCheck: true
      SSLCertRemainingLifetimeCheck: 7
    }
  }
}

resource availabilityAlert 'Microsoft.Insights/metricAlerts@2026-01-01' = if (enableAlert) {
  name: 'alert-${webTestName}-availability'
  location: 'global'
  tags: tags
  properties: {
    description: 'The deployed application failed its readiness probe from multiple regions.'
    severity: alertSeverity
    enabled: true
    scopes: [
      availabilityTest.id
      applicationInsightsId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.WebtestLocationAvailabilityCriteria'
      webTestId: availabilityTest.id
      componentId: applicationInsightsId
      failedLocationCount: failedLocationThreshold
    }
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
  }
}

output webTestId string = availabilityTest.id
output webTestName string = availabilityTest.name
output alertDeployed bool = enableAlert
