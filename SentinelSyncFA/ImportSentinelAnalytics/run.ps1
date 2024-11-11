param([byte[]] $BlobTrigger, $TriggerMetadata)
Write-Host "PowerShell Blob trigger function Processed blob! Name: $($TriggerMetadata.BlobTrigger) Size: $($BlobTrigger.Length) bytes"

#region Initialize Variables
$now = [datetime]::UtcNow
$LogAnalyticsResourceId = $env:LogAnalyticsResourceId
#$LogAnalyticsSubscriptionId = $LogAnalyticsResourceId.Split('/')[2]
#endregion Initialize Variables


#get the rules from the input file
$newRules = [System.Text.Encoding]::UTF8.GetString($BlobTrigger) | ConvertFrom-Json -Depth 99
#iterate through the rules and create the rules in Sentinel and delete old conflicting rules

$existingRules = Get-SentinelAlertRulesREST -WorkspaceId $LogAnalyticsResourceId

$count = 0
ForEach ($newRule in $newRules) {
    $count++
    If ($newRule.properties.DisplayName -notin $existingRules.properties.DisplayName) {
        Write-Verbose "Rule $count : `"$($newRule.properties.DisplayName)`" does not exist in Sentinel. Creating it."
    }
    Else {
        Write-Verbose "Rule $count : `"$($newRule.properties.DisplayName)`" already exists in Sentinel. Updating it."
        $rulesToRemove = $existingRules | Where-Object { $_.properties.DisplayName -eq $newRule.properties.DisplayName }
        ForEach ($ruleToRemove in $rulesToRemove) {
            Write-Verbose "Removing rule `"$($ruleToRemove.properties.DisplayName)`" from Sentinel to replace it with the new one."
            Remove-SentinelAlertRuleREST -RuleId $ruleToRemove.id
        }
    }
    New-SentinelAlertRuleREST -WorkspaceId $LogAnalyticsResourceId -Rule $newRule
}