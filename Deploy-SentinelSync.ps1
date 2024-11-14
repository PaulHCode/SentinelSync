<#This script will assign the Managed Identity of the Azure Function App to the Storage Blob Data Contributor role 
# on the Storage Account and Microsoft Sentinel Contributor role on the Log Analytics Workspace. 
# It will then update the Azure Function App with the latest code and update the LastUpdated tag.
#>

#Deploy the FA - currently not automated
#commercial cloud
New-AzResourceGroupDeployment -ResourceGroupName 'SentinelSync2' -TemplateFile .\bicep\deploy-functionapp.bicep -TemplateParameterFile .\bicep\parameters\deploy-functionapp-parameters-example.json
#government cloud
$deploymentResult = New-AzResourceGroupDeployment -ResourceGroupName 'SentinelSync2' -TemplateFile .\bicep\deploy-functionapp.bicep -TemplateParameterFile .\bicep\parameters\deploy-functionapp-parameters-examplegov.json

#Get info about the Function App, Log Analytics Workspace, and Storage Account
$subscriptionId = (Get-AzContext).Subscription.id
#$functionApp = Get-AzFunctionApp | Out-GridView -PassThru -Title 'Select the Function App'
$functionAppName = $deploymentResult.Parameters.functionAppName.Value #$funtionApp.Name
$functionAppRG = $deploymentResult.ResourceGroupName #$functionApp.ResourceGroupName
#$settings = Get-AzFunctionAppSetting -Name $functionApp.Name -ResourceGroupName $functionApp.ResourceGroupName -SubscriptionId $functionApp.SubscriptionId
$settings = Get-AzFunctionAppSetting -Name $functionAppName -ResourceGroupName $functionAppRG -SubscriptionId (Get-AzContext).Subscription.id #$functionApp.SubscriptionId
$storageAccountName = ($settings.AzureWebJobsStorage.split(';') | Where-Object { $_ -like "AccountName=*" }).split('=')[-1]
$managedIdentityObjectId = (Get-AzWebApp -ResourceGroupName $functionAppRG -Name $functionAppName).Identity.PrincipalId

#Assign the Managed Identity to the Storage Blob Data Contributor role on the Storage Account and Microsoft Sentinel Contributor role on the Log Analytics Workspace
New-AzRoleAssignment -ObjectId $managedIdentityObjectId -RoleDefinitionName "Storage Blob Data Contributor" -Scope "/subscriptions/$subscriptionId/resourceGroups/$functionAppRG/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
$LogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace | Out-GridView -PassThru -Title 'Select the Log Analytics Workspace'
$logAnalyticsWorkspaceId = $LogAnalyticsWorkspace.ResourceId
New-AzRoleAssignment -ObjectId $managedIdentityObjectId -RoleDefinitionName 'Microsoft Sentinel Contributor' -Scope $logAnalyticsWorkspaceId

#Deploy the latest code to the Function App
Compress-Archive -Path .\SentinelSyncFA\* -DestinationPath .\SentinelSyncFA.zip
Publish-AzWebApp -ResourceGroupName $functionAppRG -Name $functionAppName -ArchivePath .\SentinelSyncFA.zip -Force

#Update the LastUpdated tag on the Function App
Update-AzTag -ResourceId $functionApp.Id -Tag @{ 'LastUpdated' = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') } -Operation Merge
