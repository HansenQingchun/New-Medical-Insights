@description('Flex Consumption plan name.')
param planName string

@description('PubMed connector function app name.')
param pubmedFuncName string

@description('Document processor function app name.')
param docFuncName string

@description('Backing storage account name (used for function runtime).')
param storageAccountName string

@description('App Insights connection string.')
param appInsightsConnectionString string

@description('Resource ID of the user-assigned managed identity.')
param managedIdentityId string

@description('Client ID of the user-assigned managed identity.')
param managedIdentityClientId string

param location string
param tags object

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

// Deployment container required by Flex Consumption
resource deploymentContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: '${storageAccountName}/default/function-deployments'
  properties: {
    publicAccess: 'None'
  }
}

resource plan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: planName
  location: location
  tags: tags
  kind: 'functionapp,linux'
  sku: {
    tier: 'FlexConsumption'
    name: 'FC1'
  }
  properties: {
    reserved: true
  }
}

resource pubmedFunc 'Microsoft.Web/sites@2024-04-01' = {
  name: pubmedFuncName
  location: location
  tags: union(tags, {
    'azd-service-name': 'pubmed-connector'
  })
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storage.properties.primaryEndpoints.blob}function-deployments'
          authentication: {
            type: 'UserAssignedIdentity'
            userAssignedIdentityResourceId: managedIdentityId
          }
        }
      }
      runtime: {
        name: 'python'
        version: '3.11'
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 40
        instanceMemoryMB: 2048
      }
    }
    siteConfig: {
      appSettings: [
        { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: appInsightsConnectionString }
        { name: 'AzureWebJobsStorage__accountName', value: storageAccountName }
        { name: 'AzureWebJobsStorage__credential', value: 'managedidentity' }
        { name: 'AzureWebJobsStorage__clientId', value: managedIdentityClientId }
        { name: 'AZURE_CLIENT_ID', value: managedIdentityClientId }
        { name: 'NCBI_API_KEY_SECRET_NAME', value: 'ncbi-api-key' }
      ]
    }
  }
  dependsOn: [
    deploymentContainer
  ]
}

resource docFunc 'Microsoft.Web/sites@2024-04-01' = {
  name: docFuncName
  location: location
  tags: union(tags, {
    'azd-service-name': 'doc-processor'
  })
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storage.properties.primaryEndpoints.blob}function-deployments'
          authentication: {
            type: 'UserAssignedIdentity'
            userAssignedIdentityResourceId: managedIdentityId
          }
        }
      }
      runtime: {
        name: 'python'
        version: '3.11'
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 40
        instanceMemoryMB: 2048
      }
    }
    siteConfig: {
      appSettings: [
        { name: 'APPLICATIONINSIGHTS_CONNECTION_STRING', value: appInsightsConnectionString }
        { name: 'AzureWebJobsStorage__accountName', value: storageAccountName }
        { name: 'AzureWebJobsStorage__credential', value: 'managedidentity' }
        { name: 'AzureWebJobsStorage__clientId', value: managedIdentityClientId }
        { name: 'AZURE_CLIENT_ID', value: managedIdentityClientId }
      ]
    }
  }
  dependsOn: [
    deploymentContainer
  ]
}

output pubmedFunctionName string = pubmedFunc.name
output pubmedFunctionUrl string = 'https://${pubmedFunc.properties.defaultHostName}'
output docFunctionName string = docFunc.name
output docFunctionUrl string = 'https://${docFunc.properties.defaultHostName}'
