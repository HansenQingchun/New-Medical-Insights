// =========================================================================
// RBAC role assignments — wires the user-assigned managed identity (used by
// Function Apps & Copilot Studio actions) and the deploying user to the
// data planes of all created resources.
// All assignments use AAD only (local auth is disabled on each resource).
// =========================================================================

@description('Object ID of the principal running azd up (gets data-plane access for dev/seeding).')
param principalId string = ''

@description('Principal ID of the user-assigned managed identity.')
param managedIdentityPrincipalId string

param storageAccountName string
param keyVaultName string
param cosmosAccountName string
param searchServiceName string
param aiServicesName string

// ----- Existing resource references -----

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' existing = {
  name: cosmosAccountName
}

resource search 'Microsoft.Search/searchServices@2024-06-01-preview' existing = {
  name: searchServiceName
}

resource ai 'Microsoft.CognitiveServices/accounts@2024-10-01' existing = {
  name: aiServicesName
}

// ----- Role definition IDs (built-in Azure roles) -----

var roles = {
  storageBlobDataContributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  storageBlobDataOwner: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b')
  keyVaultSecretsUser: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
  keyVaultSecretsOfficer: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
  searchIndexDataContributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8ebe5a00-799e-43f5-93ac-243d3dce84a7')
  searchServiceContributor: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7ca78c08-252a-4471-8644-bb5ff32d4ba0')
  cognitiveServicesOpenAIUser: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
  cognitiveServicesUser: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')
  cosmosDbDataContributor: '00000000-0000-0000-0000-000000000002' // built-in Cosmos data plane role
}

// ----- Managed identity assignments -----

resource miStorageBlob 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storage
  name: guid(storage.id, managedIdentityPrincipalId, roles.storageBlobDataOwner)
  properties: {
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roles.storageBlobDataOwner
  }
}

resource miKeyVault 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: kv
  name: guid(kv.id, managedIdentityPrincipalId, roles.keyVaultSecretsUser)
  properties: {
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roles.keyVaultSecretsUser
  }
}

resource miSearchData 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: search
  name: guid(search.id, managedIdentityPrincipalId, roles.searchIndexDataContributor)
  properties: {
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roles.searchIndexDataContributor
  }
}

resource miSearchService 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: search
  name: guid(search.id, managedIdentityPrincipalId, roles.searchServiceContributor)
  properties: {
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roles.searchServiceContributor
  }
}

resource miAi 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: ai
  name: guid(ai.id, managedIdentityPrincipalId, roles.cognitiveServicesOpenAIUser)
  properties: {
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roles.cognitiveServicesOpenAIUser
  }
}

// Cosmos DB SQL data plane role assignment (different API)
resource miCosmosData 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = {
  parent: cosmos
  name: guid(cosmos.id, managedIdentityPrincipalId, 'cosmos-data-contributor')
  properties: {
    roleDefinitionId: '${cosmos.id}/sqlRoleDefinitions/${roles.cosmosDbDataContributor}'
    principalId: managedIdentityPrincipalId
    scope: cosmos.id
  }
}

// ----- Deploying user assignments (only if principalId is provided) -----

resource userStorageBlob 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  scope: storage
  name: guid(storage.id, principalId, roles.storageBlobDataOwner)
  properties: {
    principalId: principalId
    principalType: 'User'
    roleDefinitionId: roles.storageBlobDataOwner
  }
}

resource userKeyVault 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  scope: kv
  name: guid(kv.id, principalId, roles.keyVaultSecretsOfficer)
  properties: {
    principalId: principalId
    principalType: 'User'
    roleDefinitionId: roles.keyVaultSecretsOfficer
  }
}

resource userSearchData 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  scope: search
  name: guid(search.id, principalId, roles.searchIndexDataContributor)
  properties: {
    principalId: principalId
    principalType: 'User'
    roleDefinitionId: roles.searchIndexDataContributor
  }
}

resource userSearchService 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  scope: search
  name: guid(search.id, principalId, roles.searchServiceContributor)
  properties: {
    principalId: principalId
    principalType: 'User'
    roleDefinitionId: roles.searchServiceContributor
  }
}

resource userAi 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  scope: ai
  name: guid(ai.id, principalId, roles.cognitiveServicesOpenAIUser)
  properties: {
    principalId: principalId
    principalType: 'User'
    roleDefinitionId: roles.cognitiveServicesOpenAIUser
  }
}

resource userCosmosData 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = if (!empty(principalId)) {
  parent: cosmos
  name: guid(cosmos.id, principalId, 'cosmos-data-contributor-user')
  properties: {
    roleDefinitionId: '${cosmos.id}/sqlRoleDefinitions/${roles.cosmosDbDataContributor}'
    principalId: principalId
    scope: cosmos.id
  }
}
