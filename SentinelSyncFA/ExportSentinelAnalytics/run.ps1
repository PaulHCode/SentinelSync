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
Upload-ToBlob -ConnectionStringUri $ConnectionStringUri -fileName "SentinelRules" -timestamp $now -dataToUpload $filteredRules -storageToken $storageToken -extension 'json'

Write-Host ("Azure Analytics Rules are exported to " + $ConnectionStringURI)
