targetScope = 'resourceGroup'

// =========================================================================
// NMI Demo — Main Bicep
// =========================================================================
// Deploys the Azure infrastructure for the NMI multi-agent Copilot Studio demo:
//   - Log Analytics + Application Insights
//   - User-assigned Managed Identity
//   - Storage Account (Blob for uploads/outputs)
//   - Key Vault (secrets)
//   - Cosmos DB SQL (writing instructions, rules, task state)
//   - Azure AI Search (glossary, reference store, KB)
//   - Azure AI Foundry / AI Services (GPT-4o model deployment)
//   - Azure Functions (Flex Consumption) for PubMed connector & doc processing
//   - Role assignments wiring the managed identity to all resources
//
// Note: Microsoft Copilot Studio agents themselves are configured in the
// Copilot Studio UI (or via the Power Platform CLI), not via Bicep.
// =========================================================================

// ----- Parameters -----

@minLength(2)
@maxLength(10)
@description('Short environment name (e.g. dev, demo, poc).')
param environmentName string

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Azure region for AI Search (can differ from main location due to capacity).')
param searchLocation string = location

@description('Resource name token; defaults to a unique suffix from RG id.')
param resourceToken string = toLower(uniqueString(subscription().id, resourceGroup().id, environmentName))

@description('Object ID (GUID) of the principal (user / service principal) running azd up. Used for Key Vault and data-plane RBAC. Get via: az ad signed-in-user show --query id -o tsv')
param principalId string = ''

@description('AI Foundry model deployment name. Default GPT-4o.')
param chatModelName string = 'gpt-4o'

@description('AI Foundry model version.')
param chatModelVersion string = '2024-11-20'

@description('Tokens-per-minute capacity for the chat model (in thousands).')
param chatModelCapacity int = 30

@description('Tags applied to all resources.')
param tags object = {
  'azd-env-name': environmentName
  workload: 'nmi-demo'
  costCenter: 'demo'
}

// ----- Naming -----

var prefix = 'nmi-${environmentName}'
var prefixShort = take(replace(prefix, '-', ''), 11)

var names = {
  logAnalytics: '${prefix}-log-${resourceToken}'
  appInsights: '${prefix}-appi-${resourceToken}'
  managedIdentity: '${prefix}-mi-${resourceToken}'
  storage: take('${prefixShort}st${resourceToken}', 24)
  keyVault: take('${prefix}-kv-${resourceToken}', 24)
  cosmos: '${prefix}-cosmos-${resourceToken}'
  aiSearch: '${prefix}-search-${resourceToken}'
  aiServices: '${prefix}-aifoundry-${resourceToken}'
  functionPlan: '${prefix}-flex-${resourceToken}'
  pubmedFunc: '${prefix}-fn-pubmed-${resourceToken}'
  docFunc: '${prefix}-fn-doc-${resourceToken}'
}

// ----- Modules -----

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    logAnalyticsName: names.logAnalytics
    appInsightsName: names.appInsights
    location: location
    tags: tags
  }
}

module identity 'modules/identity.bicep' = {
  name: 'identity'
  params: {
    name: names.managedIdentity
    location: location
    tags: tags
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    // Actual computed length is always >= 16 chars; linter cannot statically prove it.
    #disable-next-line BCP334
    name: names.storage
    location: location
    tags: tags
  }
}

module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    name: names.keyVault
    location: location
    tags: tags
  }
}

module cosmos 'modules/cosmos.bicep' = {
  name: 'cosmos'
  params: {
    accountName: names.cosmos
    location: location
    tags: tags
  }
}

module search 'modules/aisearch.bicep' = {
  name: 'aisearch'
  params: {
    name: names.aiSearch
    location: searchLocation
    tags: tags
  }
}

module aifoundry 'modules/aifoundry.bicep' = {
  name: 'aifoundry'
  params: {
    name: names.aiServices
    location: location
    tags: tags
    chatModelName: chatModelName
    chatModelVersion: chatModelVersion
    chatModelCapacity: chatModelCapacity
  }
}

module functions 'modules/functionapp.bicep' = {
  name: 'functions'
  params: {
    planName: names.functionPlan
    pubmedFuncName: names.pubmedFunc
    docFuncName: names.docFunc
    storageAccountName: storage.outputs.name
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    managedIdentityId: identity.outputs.id
    managedIdentityClientId: identity.outputs.clientId
    location: location
    tags: tags
  }
}

module rbac 'modules/rbac.bicep' = {
  name: 'rbac'
  params: {
    principalId: principalId
    managedIdentityPrincipalId: identity.outputs.principalId
    storageAccountName: storage.outputs.name
    keyVaultName: keyvault.outputs.name
    cosmosAccountName: cosmos.outputs.accountName
    searchServiceName: search.outputs.name
    aiServicesName: aifoundry.outputs.name
  }
}

// ----- Outputs (consumed by azd / app code) -----

output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = resourceGroup().name
output AZURE_TENANT_ID string = subscription().tenantId

output AZURE_MANAGED_IDENTITY_ID string = identity.outputs.id
output AZURE_MANAGED_IDENTITY_CLIENT_ID string = identity.outputs.clientId

output AZURE_STORAGE_ACCOUNT string = storage.outputs.name
output AZURE_STORAGE_BLOB_ENDPOINT string = storage.outputs.blobEndpoint

output AZURE_KEY_VAULT_NAME string = keyvault.outputs.name
output AZURE_KEY_VAULT_ENDPOINT string = keyvault.outputs.endpoint

output AZURE_COSMOS_ACCOUNT string = cosmos.outputs.accountName
output AZURE_COSMOS_ENDPOINT string = cosmos.outputs.endpoint
output AZURE_COSMOS_DATABASE string = cosmos.outputs.databaseName

output AZURE_SEARCH_SERVICE string = search.outputs.name
output AZURE_SEARCH_ENDPOINT string = search.outputs.endpoint

output AZURE_AI_FOUNDRY_NAME string = aifoundry.outputs.name
output AZURE_AI_FOUNDRY_ENDPOINT string = aifoundry.outputs.endpoint
output AZURE_AI_FOUNDRY_CHAT_MODEL string = chatModelName
output AZURE_AI_FOUNDRY_CHAT_DEPLOYMENT string = aifoundry.outputs.chatDeploymentName

output AZURE_FUNCTION_PUBMED_URL string = functions.outputs.pubmedFunctionUrl
output AZURE_FUNCTION_DOC_URL string = functions.outputs.docFunctionUrl

output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.appInsightsConnectionString
