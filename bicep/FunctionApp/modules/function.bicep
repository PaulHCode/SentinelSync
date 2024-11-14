param files object
param functionAppName string
param functionName string
param bindings array

resource functionApp 'Microsoft.Web/sites@2020-12-01' existing = {
  name: functionAppName
}

resource function 'Microsoft.Web/sites/functions@2020-12-01' = {
  parent: functionApp
  name: functionName
  properties: {
    config: {
      disabled: false
      bindings: bindings
    }
    files: files
  }
}
