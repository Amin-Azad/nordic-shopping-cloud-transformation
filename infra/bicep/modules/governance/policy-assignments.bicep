targetScope = 'subscription'

@description('deployment environment.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string

@description('approved azure locations for nordic shopping platform.')
param allowedLocations array

@description('must contains tag names')
param requiredTagNames array

@description('Controls whether the audit policy assignments are active.')
@allowed([
  'Audit'
  'Disabled'
])
param auditEffect string = 'Audit'

// Built-in Azure Policy definition IDs
var allowedLocationsPolicyDefinitionId = 'e56962a6-4747-49cd-b67b-bf8b01975c4c'
var requireTagPolicyDefinitionId = '871b6d14-10aa-478d-b590-94f262ecfa99'
var storageSecureTransferPolicyDefinitionId = '404c3081-a854-4457-ae30-26a93ef643f9'
var storageMinimumTlsPolicyDefinitionId = 'fe83a0eb-a853-422d-aac2-1bffd182c5d0'
var storagePublicNetworkAccessPolicyDefinitionId = 'b2982f36-99f2-4db5-8eff-283140c09693'
var storageAnonymousBlobAccessPolicyDefinitionId = '4fa4b6c0-31ca-4c0d-b10d-24b96f62a751'
var keyVaultPublicNetworkAccessPolicyDefinitionId = '405c5871-3e91-4644-8a63-58e19d68ff5b'
var keyVaultPurgeProtectionPolicyDefinitionId = '0b60c0b2-2dc2-4e1c-b5c9-abbed971de53'
var sqlPublicNetworkAccessPolicyDefinitionId = '1b8ca024-1d5c-4dec-8995-b1a932b41780'
var sqlMinimumTlsPolicyDefinitionId = '32e6bbec-16b6-44c2-be37-c5b672d103cf'
var appServicePublicNetworkAccessPolicyDefinitionId = '1b5ef780-c53c-4a64-87f3-bb9c8c8094ba'
var appServiceHttpsOnlyPolicyDefinitionId = 'a4af4a39-4135-47fb-b175-47fbdf85311d'
var appServiceMinimumTlsPolicyDefinitionId = 'f0e6e85b-9b9f-4a4b-b67b-f730d42f1b0b'
var appServiceManagedIdentityPolicyDefinitionId = '2b9ad585-36bc-4615-b300-fd4435808332'
var appServiceRemoteDebuggingPolicyDefinitionId = 'cb510bfd-1cba-4d9f-a230-cb0976f4bb71'
var appServiceFtpBasicAuthPolicyDefinitionId = '871b205b-57cf-4e1e-a234-492616998bf7'
var appServiceScmBasicAuthPolicyDefinitionId = 'aede300b-d67f-480a-ae26-4b3dfb1a1fdc'
var storageSharedKeyPolicyDefinitionId = '8c6a50c6-9ffd-4ae7-986f-5fa6111f9a54'
var keyVaultRbacPolicyDefinitionId = '12d4fa5e-1f9f-4c21-97a9-b99b3c6611b5'
var aiServicesNetworkAccessPolicyDefinitionId = '037eea7a-bd0a-46c5-9a66-03aea78705d3'

// Reference existing built-in policy definitions
resource allowedLocationsPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: allowedLocationsPolicyDefinitionId
  scope: tenant()
}

resource requireTagPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: requireTagPolicyDefinitionId
  scope: tenant()
}
resource storageSecureTransferPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: storageSecureTransferPolicyDefinitionId
  scope: tenant()
}
resource storageMinimumTlsPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: storageMinimumTlsPolicyDefinitionId
  scope: tenant()
}

resource storagePublicNetworkAccessPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: storagePublicNetworkAccessPolicyDefinitionId
  scope: tenant()
}

resource storageAnonymousBlobAccessPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: storageAnonymousBlobAccessPolicyDefinitionId
  scope: tenant()
}

resource keyVaultPublicNetworkAccessPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: keyVaultPublicNetworkAccessPolicyDefinitionId
  scope: tenant()
}

resource keyVaultPurgeProtectionPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: keyVaultPurgeProtectionPolicyDefinitionId
  scope: tenant()
}

resource sqlPublicNetworkAccessPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: sqlPublicNetworkAccessPolicyDefinitionId
  scope: tenant()
}

resource sqlMinimumTlsPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: sqlMinimumTlsPolicyDefinitionId
  scope: tenant()
}
resource appServicePublicNetworkAccessPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: appServicePublicNetworkAccessPolicyDefinitionId
  scope: tenant()
}

resource appServiceHttpsOnlyPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: appServiceHttpsOnlyPolicyDefinitionId
  scope: tenant()
}
resource appServiceMinimumTlsPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: appServiceMinimumTlsPolicyDefinitionId
  scope: tenant()
}
resource appServiceManagedIdentityPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: appServiceManagedIdentityPolicyDefinitionId
  scope: tenant()
}
resource appServiceRemoteDebuggingPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: appServiceRemoteDebuggingPolicyDefinitionId
  scope: tenant()
}
// App Service: disable FTP basic authentication
resource appServiceFtpBasicAuthPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: appServiceFtpBasicAuthPolicyDefinitionId
  scope: tenant()
}

// App Service: disable SCM basic authentication
resource appServiceScmBasicAuthPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: appServiceScmBasicAuthPolicyDefinitionId
  scope: tenant()
}

// Storage: disable shared-key access
resource storageSharedKeyPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: storageSharedKeyPolicyDefinitionId
  scope: tenant()
}

// Key Vault: use the Azure RBAC permission model
resource keyVaultRbacPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: keyVaultRbacPolicyDefinitionId
  scope: tenant()
}

// Azure AI Services: restrict public network access
resource aiServicesNetworkAccessPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: aiServicesNetworkAccessPolicyDefinitionId
  scope: tenant()
}

// Allow resources only in approved Azure regions
resource allowedLocationsPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-allowed-locations'
  properties: {
    displayName: 'Nordic Shopping - Allowed locations (${environment})'
    description: 'Audits resources deployed outside the approved Nordic Shopping Azure regions.'
    policyDefinitionId: allowedLocationsPolicyDefinition.id
    enforcementMode: 'Default'
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
      effect: {
        value: auditEffect
      }
    }
    metadata: {
      category: 'Governance'
      environment: environment
      managedBy: 'Bicep'
    }
    nonComplianceMessages: [
      {
        message: 'Deploy resources only in the Azure locations approved for Nordic Shopping.'
      }
    ]
  }
}

// Check that every resource contains the required tags
resource requiredTagPolicyAssignments 'Microsoft.Authorization/policyAssignments@2025-01-01' = [
  for tagName in requiredTagNames: {
    name: 'nshop-${environment}-require-${toLower(tagName)}'
    properties: {
      displayName: 'Nordic Shopping - Require ${tagName} tag (${environment})'
      description: 'Checks whether Nordic Shopping resources contain the ${tagName} tag.'
      policyDefinitionId: requireTagPolicyDefinition.id

      // The built-in policy uses Deny, but DoNotEnforce prevents blocking.
      enforcementMode: 'DoNotEnforce'

      parameters: {
        tagName: {
          value: tagName
        }
      }

      metadata: {
        category: 'Governance'
        environment: environment
        managedBy: 'Bicep'
      }

      nonComplianceMessages: [
        {
          message: 'Add the required ${tagName} tag to this Nordic Shopping resource.'
        }
      ]
    }
  }
]
// Check that Storage Accounts accept only secure HTTPS connections
resource storageSecureTransferPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-storage-https'
  properties: {
    displayName: 'Nordic Shopping - Storage secure transfer (${environment})'
    description: 'Audits Storage Accounts that do not require secure HTTPS connections.'
    policyDefinitionId: storageSecureTransferPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping Storage Accounts must require secure HTTPS connections.'
      }
    ]
  }
}
// Check that Storage Accounts require TLS 1.2
resource storageMinimumTlsPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-storage-tls'
  properties: {
    displayName: 'Nordic Shopping - Storage minimum TLS (${environment})'
    description: 'Audits Storage Accounts that do not require TLS 1.2.'
    policyDefinitionId: storageMinimumTlsPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect
      }
      minimumTlsVersion: {
        value: 'TLS1_2'
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping Storage Accounts must require TLS 1.2.'
      }
    ]
  }
}

// Check that public network access is disabled for Storage Accounts
resource storagePublicNetworkAccessPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-storage-public-access'
  properties: {
    displayName: 'Nordic Shopping - Storage public network access (${environment})'
    description: 'Audits Storage Accounts that allow public network access.'
    policyDefinitionId: storagePublicNetworkAccessPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping Storage Accounts must disable public network access and use private endpoints.'
      }
    ]
  }
}
// Check that anonymous public access to blobs and containers is disabled
resource storageAnonymousBlobAccessPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-storage-blob-public'
  properties: {
    displayName: 'Nordic Shopping - Disable anonymous blob access (${environment})'
    description: 'Audits Storage Accounts that permit anonymous public access to blobs and containers.'
    policyDefinitionId: storageAnonymousBlobAccessPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping Storage Accounts must disable anonymous public access to blobs and containers.'
      }
    ]
  }
}
// Check that public network access is disabled for Key Vault
resource keyVaultPublicNetworkAccessPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-keyvault-public-access'
  properties: {
    displayName: 'Nordic Shopping - Key Vault public network access (${environment})'
    description: 'Audits Key Vaults that allow public network access.'
    policyDefinitionId: keyVaultPublicNetworkAccessPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping Key Vaults must disable public network access and use private endpoints.'
      }
    ]
  }
}
// Check that purge protection is enabled for Key Vault
resource keyVaultPurgeProtectionPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-keyvault-purge-protection'
  properties: {
    displayName: 'Nordic Shopping - Key Vault purge protection (${environment})'
    description: 'Audits Key Vaults that do not have purge protection enabled.'
    policyDefinitionId: keyVaultPurgeProtectionPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping Key Vaults must have purge protection enabled.'
      }
    ]
  }
}
// Check that public network access is disabled for Azure SQL
resource sqlPublicNetworkAccessPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-sql-public-access'
  properties: {
    displayName: 'Nordic Shopping - SQL public network access (${environment})'
    description: 'Audits Azure SQL logical servers that allow public network access.'
    policyDefinitionId: sqlPublicNetworkAccessPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping Azure SQL servers must disable public network access and use private endpoints.'
      }
    ]
  }
}
// Check that Azure SQL logical servers require TLS 1.2 or newer
resource sqlMinimumTlsPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-sql-tls'
  properties: {
    displayName: 'Nordic Shopping - SQL minimum TLS (${environment})'
    description: 'Audits Azure SQL logical servers that do not require TLS 1.2 or newer.'
    policyDefinitionId: sqlMinimumTlsPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping Azure SQL logical servers must require TLS 1.2 or newer.'
      }
    ]
  }
}
// Check that public network access is disabled for App Service web apps
resource appServicePublicNetworkAccessPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-app-public-access'
  properties: {
    displayName: 'Nordic Shopping - App Service public network access (${environment})'
    description: 'Audits App Service web apps that allow public network access.'
    policyDefinitionId: appServicePublicNetworkAccessPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping App Service web apps must disable public network access.'
      }
    ]
  }
}
// Check that App Service web apps redirect HTTP traffic to HTTPS
resource appServiceHttpsOnlyPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-app-https'
  properties: {
    displayName: 'Nordic Shopping - App Service HTTPS only (${environment})'
    description: 'Audits App Service web apps that do not enforce HTTPS.'
    policyDefinitionId: appServiceHttpsOnlyPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping App Service web apps must allow HTTPS traffic only.'
      }
    ]
  }
}
// Check that App Service web apps require TLS 1.2 or newer
resource appServiceMinimumTlsPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-app-tls'
  properties: {
    displayName: 'Nordic Shopping - App Service minimum TLS (${environment})'
    description: 'Audits App Service web apps that allow inbound TLS versions older than 1.2.'
    policyDefinitionId: appServiceMinimumTlsPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect == 'Disabled' ? 'Disabled' : 'AuditIfNotExists'
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping App Service web apps must require TLS 1.2 or newer.'
      }
    ]
  }
}
// Check that App Service web apps use managed identity
resource appServiceManagedIdentityPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-app-managed-identity'
  properties: {
    displayName: 'Nordic Shopping - App Service managed identity (${environment})'
    description: 'Audits App Service web apps that do not use managed identity.'
    policyDefinitionId: appServiceManagedIdentityPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect == 'Disabled' ? 'Disabled' : 'AuditIfNotExists'
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping App Service web apps must use managed identity for access to Azure services.'
      }
    ]
  }
}
// Check that remote debugging is disabled for App Service web apps
resource appServiceRemoteDebuggingPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-app-remote-debug'
  properties: {
    displayName: 'Nordic Shopping - Disable App Service remote debugging (${environment})'
    description: 'Audits App Service web apps that have remote debugging enabled.'
    policyDefinitionId: appServiceRemoteDebuggingPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect == 'Disabled' ? 'Disabled' : 'AuditIfNotExists'
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping App Service web apps must have remote debugging disabled.'
      }
    ]
  }
}
// Check that App Service FTP deployments do not use basic authentication
resource appServiceFtpBasicAuthPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-app-ftp-basic-auth'
  properties: {
    displayName: 'Nordic Shopping - Disable App Service FTP basic authentication (${environment})'
    description: 'Audits App Service web apps that allow local authentication for FTP deployments.'
    policyDefinitionId: appServiceFtpBasicAuthPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect == 'Disabled' ? 'Disabled' : 'AuditIfNotExists'
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping App Service web apps must disable basic authentication for FTP deployments.'
      }
    ]
  }
}

// Check that App Service SCM deployments do not use basic authentication
resource appServiceScmBasicAuthPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-app-scm-basic-auth'
  properties: {
    displayName: 'Nordic Shopping - Disable App Service SCM basic authentication (${environment})'
    description: 'Audits App Service web apps that allow local authentication for SCM site deployments.'
    policyDefinitionId: appServiceScmBasicAuthPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect == 'Disabled' ? 'Disabled' : 'AuditIfNotExists'
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping App Service web apps must disable basic authentication for SCM site deployments.'
      }
    ]
  }
}

// Check that Storage Accounts prevent shared-key authorization
resource storageSharedKeyPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-storage-shared-key'
  properties: {
    displayName: 'Nordic Shopping - Disable Storage shared-key access (${environment})'
    description: 'Audits Storage Accounts that permit authorization with account access keys.'
    policyDefinitionId: storageSharedKeyPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping Storage Accounts must disable shared-key access and use Microsoft Entra authentication.'
      }
    ]
  }
}

// Check that Key Vault uses the Azure RBAC permission model
resource keyVaultRbacPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-keyvault-rbac'
  properties: {
    displayName: 'Nordic Shopping - Key Vault Azure RBAC permission model (${environment})'
    description: 'Audits Key Vaults that use legacy access policies instead of the Azure RBAC permission model.'
    policyDefinitionId: keyVaultRbacPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping Key Vaults must use the Azure RBAC permission model.'
      }
    ]
  }
}

// Check that Azure AI Services restrict public network access
resource aiServicesNetworkAccessPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'nshop-${environment}-ai-network-access'
  properties: {
    displayName: 'Nordic Shopping - Restrict Azure AI Services network access (${environment})'
    description: 'Audits Azure AI Services accounts that permit unrestricted public network access.'
    policyDefinitionId: aiServicesNetworkAccessPolicyDefinition.id
    enforcementMode: 'Default'

    parameters: {
      effect: {
        value: auditEffect
      }
    }

    metadata: {
      category: 'Security'
      environment: environment
      managedBy: 'Bicep'
    }

    nonComplianceMessages: [
      {
        message: 'Nordic Shopping Azure AI Services accounts must disable public access and restrict network access.'
      }
    ]
  }
}
output policyAssignmentCount int = 19 + length(requiredTagNames)
output policyControlCount int = 20
