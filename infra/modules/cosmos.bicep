@description('Cosmos DB account name (3-44 chars, lowercase alphanumeric and dashes).')
param accountName string

param location string
param tags object

@description('Cosmos SQL database name.')
param databaseName string = 'nmi'

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: accountName
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
    disableLocalAuth: true
    minimalTlsVersion: 'Tls12'
    publicNetworkAccess: 'Enabled'
  }
}

resource db 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmos
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource writingInstructionsContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  parent: db
  name: 'writing_instructions'
  properties: {
    resource: {
      id: 'writing_instructions'
      partitionKey: {
        paths: ['/id']
        kind: 'Hash'
      }
    }
  }
}

resource writingRulesContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  parent: db
  name: 'writing_rules'
  properties: {
    resource: {
      id: 'writing_rules'
      partitionKey: {
        paths: ['/ruleset_id']
        kind: 'Hash'
      }
    }
  }
}

resource taskStateContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  parent: db
  name: 'task_state'
  properties: {
    resource: {
      id: 'task_state'
      partitionKey: {
        paths: ['/user_id']
        kind: 'Hash'
      }
      defaultTtl: 604800 // 7 days
    }
  }
}

output id string = cosmos.id
output accountName string = cosmos.name
output endpoint string = cosmos.properties.documentEndpoint
output databaseName string = databaseName
