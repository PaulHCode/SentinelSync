param($Timer)

#region Initialize Variables
$sentinelResourceId = $env:SentinelResourceId
$sentinelResourceId = $sentinelResourceId.replace('SecurityInsights(', '').replace(')', '')
$ConnectionStringUri = $env:SentinelAnalyticsOutputURL

$sentinelSubscriptionId = $sentinelResourceId.Split('/')[2]
$sentinelResourceGroupName = $sentinelResourceId.Split('/')[4]
$sentinelWorkspaceName = $sentinelResourceId.Split('/')[8]
$now = ([System.DateTime]::UtcNow).ToString("yyyy-MM-ddTHHmmss")

$rulesToExportStartWith = @('Exploitation', 'Suspicious', 'Anomalous', 'Malicious', 'Behavior', 'Threat', 'Alert', 'Detection', 'Incident', 'Investigation', 'Security', 'Advanced', 'Paul')
$rulesToNotExportStartWith = @('Test')

#endregion Initialize Variables

#region Functions
Function Filter-Rules {
    param(
        [Parameter(Mandatory = $true)]
        $rules,
        [Parameter(Mandatory = $false)]
        [string[]]
        $RulesToExportStartWith,
        [Parameter(Mandatory = $false)]
        [string[]]
        $RulesToNotExportStartWith
    )
    If ($RulesToExportStartWith) {
        $includedRules = ForEach ($filter in $RulesToExportStartWith) {
            $rules | Where-Object { $_.properties.DisplayName -like "$filter*" }
        }
    }
    Else {
        $includedRules = $rules
    }
    If ($RulesToNotExportStartWith) {
        $notExcludedRules = ForEach ($filter in $RulesToNotExportStartWith) {
            $includedRules | Where-Object { $_.properties.DisplayName -notlike "$filter*" }
        }
    }
    Else {
        $notExcludedRules = $includedRules
    }
    $notExcludedRules
}

Function Convert-SentinelRulesToPortalImportable {
    param(
        [Parameter(Mandatory = $true)]
        $exportedRules
    )
    #convert individual Rules
    ForEach ($rule in $exportedRules) {
        #update ID
        $rule.id = "[concat(resourceId('Microsoft.OperationalInsights/workspaces/providers', parameters('workspace'), 'Microsoft.SecurityInsights'),'/alertRules/$($rule.id.split('/')[-1])')]"
        #update name
        $rule.name = "[concat(parameters('workspace'),'/Microsoft.SecurityInsights/$($rule.name)')]"
        #update Type
        $rule.type = "Microsoft.OperationalInsights/workspaces/providers/alertRules"
        #update apiVersion
        $rule | Add-Member -MemberType NoteProperty -Name 'apiVersion' -Value "2023-12-01-preview"
        #remove lastModifiedUtc
        $rule.properties = $rule.properties | Select-Object * -ExcludeProperty lastModifiedUtc
    }
    #remove Etag
    $exportedRules = ForEach ($rule in $exportedRules) { $rule | Select-Object * -ExcludeProperty etag }

    #add rules to larger structure required
    $exportableRules = [PSCustomObject]@{
        '$schema'        = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
        'contentVersion' = '1.0.0.0'
        'parameters'     = [PSCustomObject]@{
            'workspace' = [PSCustomObject]@{
                'type' = 'String'
            }
        }
        'resources'      = [array]$exportedRules
    }
    $exportableRules
}
#endregion Functions

#region Get Sentinel Rules
$resourceManagerToken = Connect-AcquireToken -TokenResourceUrl $ResourceManagerUrl
#$resourceManagerToken = (Get-AzAccessToken -ResourceUrl $ResourceManagerUrl).token
$uri = "$resourceManagerUrl/subscriptions/$sentinelSubscriptionId/resourceGroups/$sentinelResourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$sentinelWorkspaceName/providers/Microsoft.SecurityInsights/alertRules?api-version=2024-03-01"


#    $uri = "$resourceManagerUrl"+"$sentinelResourceId"+"/providers/Microsoft.SecurityInsights/alertRules?api-version=2024-03-01"
$rules = Invoke-AzureRestMethod -AccessToken $resourceManagerToken -Uri $uri -Method Get
$filteredRules = Filter-Rules -rules $rules -RulesToExportStartWith $rulesToExportStartWith -RulesToNotExportStartWith $rulesToNotExportStartWith

$storageToken = Connect-AcquireToken -TokenResourceUrl $storageTokenUrl
$timestamp = $now#.tostring('yyyy-MM-dd_HHmmss')
Upload-ToBlob -ConnectionStringUri $ConnectionStringUri -fileName "SentinelRules-AutoImport" -timestamp $now -dataToUpload $filteredRules -storageToken $storageToken -extension 'json'

$portalImportableRules = Convert-SentinelRulesToPortalImportable -exportedRules $filteredRules
Upload-ToBlob -ConnectionStringUri $ConnectionStringUri -fileName "SentinelRules-PortalImportable" -timestamp $now -dataToUpload $portalImportableRules -storageToken $storageToken -extension 'json'

Write-Host ("Azure Analytics Rules are exported to " + $ConnectionStringURI)