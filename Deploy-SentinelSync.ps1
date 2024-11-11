<#This script will assign the Managed Identity of the Azure Function App to the Storage Blob Data Contributor role 
# on the Storage Account and Microsoft Sentinel Contributor role on the Log Analytics Workspace. 
# It will then update the Azure Function App with the latest code and update the LastUpdated tag.
#>

#Deploy the FA - currently not automated

#Get info about the Function App, Log Analytics Workspace, and Storage Account
$subscriptionId = (Get-AzContext).Subscription.id
$functionApp = Get-AzFunctionApp | Out-GridView -PassThru -Title 'Select the Function App'
$functionAppName = $funtionApp.Name
$functionAppRG = $functionApp.ResourceGroupName
$settings = Get-AzFunctionAppSetting -Name $functionApp.Name -ResourceGroupName $functionApp.ResourceGroupName -SubscriptionId $functionApp.SubscriptionId
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
