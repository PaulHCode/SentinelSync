metadata name = 'SentinelSync'
metadata description = 'This template deploys a function app with a storage account and an app service plan'

param location string
param functionAppName string
param storageAccountName string
param storageAccountType string
param appServicePlanName string
param fileshareName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource fileservices 'Microsoft.Storage/storageAccounts/fileServices@2021-02-01' = {
  name: fileshareName
  parent: storageAccount
  dependsOn: [
    storageAccount
  ]
}

resource fileshare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-02-01' = {
  name: fileshareName
  parent: fileservices
  properties: {
    shareQuota: 1024
  }
  dependsOn: [
    fileservices
  ]
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2021-02-01' = {
  name: functionAppName
  kind: 'functionapp'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: storageAccount.properties.primaryEndpoints.blob
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'powershell'
        }
        {
          name: 'LogAnalyticsResourceId'
          value: ''
        }
        {
          name: 'SentinelAnalyticsOutputURL'
          value: ''
        }
        {
          name: 'SentinelResourceId'
          value: ''
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: storageAccount.properties.primaryEndpoints.file
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: fileshareName
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
      ]
    }
  }
  dependsOn: [
    storageAccount
    appServicePlan
  ]
}

output functionAppEndpoint string = functionApp.properties.defaultHostName
