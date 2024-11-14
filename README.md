# SentinelSync
Helps Synchronize Sentinel Instances

## Blue Button Deployment

| Deployment Type | Link |
|:--|:--|
| Azure portal UI |[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fshawntmeyer%2FSentinelSync%2Frefs%2Fheads%2FDeployment%2Fdeployment%2FfunctionApp.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fshawntmeyer%2FSentinelSync%2Frefs%2Fheads%2FDeployment%2Fdeployment%2FuiFormDefinition.json) [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/?feature.deployapiver=2022-12-01#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fshawntmeyer%2FSentinelSync%2Frefs%2Fheads%2FDeployment%2Fdeployment%2FfunctionApp.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fshawntmeyer%2FSentinelSync%2Frefs%2Fheads%2FDeployment%2Fdeployment%2FuiFormDefinition.json)

## Installation
The function app does not require any PowerShell modules however the script to deploy it currently assumes you have the following modules installed. I plan to remove this dependency in the future.
- Az.Accounts
- Az.Resources
- Az.Functions
- Az.OperationalInsights
- Az.Websites

```PowerShell
    # Connect-AzAccount to the right tenant and set-azcontext to the right subscription first
   .\Deploy-SentinelSync.ps1
   # After running this script you will be prompted for: which function app to update and which log analytics workspace to work with
```
Configure Function App Settings:
- `LogAnalyticsResourceId` - The resource id of the log analytics workspace
- `SentinelResourceId` - The resource id of the sentinel instance
- `SentinelAnalyticsOutputUrl` - The URL to the Sentinel Analytics output

Configure the storage account:
- Create a container called `sentinelanalyticsinput` in the storage account
