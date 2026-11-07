#Requires -Version 7.2
#Requires -Modules Microsoft.Graph.Authentication

<#
.SYNOPSIS
    Checks directory synchronization and password hash sync health in Microsoft Entra ID.

.DESCRIPTION
    Uses Microsoft Graph to report:

      - tenant onPremisesSyncEnabled, last directory sync and last password sync times
      - on-premises synchronization features (password hash sync, accidental deletion prevention)
      - authentication type of every verified domain (Federated or Managed)
      - synced users that carry provisioning errors (sampled)

    Returns a result object and sets a non-zero exit code when a check fails, so it can gate a
    migration wave or run in a pipeline.

.PARAMETER MaxSyncAgeMinutes
    Maximum minutes since the last directory sync before the check fails. The default sync cycle
    is 30 minutes for Connect Sync and 2 minutes for Cloud Sync.

.PARAMETER MaxPasswordSyncAgeMinutes
    Maximum minutes since the last password hash sync heartbeat before the check fails.

.PARAMETER UserSampleSize
    Number of synced users to inspect for provisioning errors.

.PARAMETER OutputPath
    Optional path for a JSON copy of the result.

.EXAMPLE
    ./Test-HybridSyncHealth.ps1

.EXAMPLE
    ./Test-HybridSyncHealth.ps1 -MaxSyncAgeMinutes 60 -OutputPath ./out/sync-health.json

.NOTES
    Author: Purushotham Muktha
    Graph scopes: Organization.Read.All, OnPremDirectorySynchronization.Read.All, Domain.Read.All, User.Read.All.
    Connect beforehand with Connect-MgGraph, or let the script prompt interactively.
    Reference: https://learn.microsoft.com/graph/api/resources/onpremisesdirectorysynchronization
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateRange(5, 1440)]
    [int] $MaxSyncAgeMinutes = 90,

    [ValidateRange(5, 1440)]
    [int] $MaxPasswordSyncAgeMinutes = 120,

    [ValidateRange(0, 10000)]
    [int] $UserSampleSize = 999,

    [string] $OutputPath
)

Set-StrictMode -Version Latest
# Graph responses stay as hashtables: absent properties read as $null under strict mode.
$ErrorActionPreference = 'Stop'

$scopes = @('Organization.Read.All', 'OnPremDirectorySynchronization.Read.All', 'Domain.Read.All', 'User.Read.All')
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes -NoWelcome }

function Get-GraphCollection {
    param([Parameter(Mandatory)] [string] $Uri, [int] $Limit = [int]::MaxValue, [hashtable] $Headers = @{})
    $items = [System.Collections.Generic.List[object]]::new()
    $next = $Uri
    while ($next -and $items.Count -lt $Limit) {
        $page = Invoke-MgGraphRequest -Method GET -Uri $next -Headers $Headers
        foreach ($v in @($page.value)) { if ($items.Count -lt $Limit) { $items.Add($v) } }
        $next = $page.'@odata.nextLink'
    }
    return $items
}

$checks = [System.Collections.Generic.List[pscustomobject]]::new()
function Add-Check {
    param([string] $Name, [ValidateSet('Pass', 'Warn', 'Fail')] [string] $Status, [string] $Detail)
    $checks.Add([pscustomobject]@{ Check = $Name; Status = $Status; Detail = $Detail })
}

$now = [datetime]::UtcNow

$org = (Invoke-MgGraphRequest -Method GET `
        -Uri 'v1.0/organization?$select=id,displayName,onPremisesSyncEnabled,onPremisesLastSyncDateTime,onPremisesLastPasswordSyncDateTime').value | Select-Object -First 1

if ($org.onPremisesSyncEnabled) {
    Add-Check 'DirectorySyncEnabled' Pass 'onPremisesSyncEnabled is true.'
}
else {
    Add-Check 'DirectorySyncEnabled' Fail 'onPremisesSyncEnabled is not true; no sync engine is connected.'
}

if ($org.onPremisesLastSyncDateTime) {
    $age = [int]($now - ([datetime]$org.onPremisesLastSyncDateTime).ToUniversalTime()).TotalMinutes
    $status = if ($age -le $MaxSyncAgeMinutes) { 'Pass' } else { 'Fail' }
    Add-Check 'LastDirectorySync' $status "$age minutes ago (threshold $MaxSyncAgeMinutes)."
}
else {
    Add-Check 'LastDirectorySync' Fail 'No directory sync has been recorded.'
}

if ($org.onPremisesLastPasswordSyncDateTime) {
    $age = [int]($now - ([datetime]$org.onPremisesLastPasswordSyncDateTime).ToUniversalTime()).TotalMinutes
    $status = if ($age -le $MaxPasswordSyncAgeMinutes) { 'Pass' } else { 'Fail' }
    Add-Check 'LastPasswordHashSync' $status "$age minutes ago (threshold $MaxPasswordSyncAgeMinutes)."
}
else {
    Add-Check 'LastPasswordHashSync' Fail 'No password hash sync has been recorded. Staged rollout and domain conversion require PHS.'
}

try {
    $sync = (Invoke-MgGraphRequest -Method GET -Uri 'v1.0/directory/onPremisesSynchronization').value | Select-Object -First 1
    $features = $sync.features
    if ($features.passwordSyncEnabled) {
        Add-Check 'PasswordHashSyncFeature' Pass 'passwordSyncEnabled is true.'
    }
    else {
        Add-Check 'PasswordHashSyncFeature' Fail 'passwordSyncEnabled is false.'
    }
    $deletion = $sync.configuration.accidentalDeletionPrevention
    if ($deletion -and $deletion.synchronizationPreventionType -ne 'disabled') {
        Add-Check 'AccidentalDeletionPrevention' Pass "$($deletion.synchronizationPreventionType), threshold $($deletion.alertThreshold)."
    }
    else {
        Add-Check 'AccidentalDeletionPrevention' Warn 'Accidental deletion prevention is disabled.'
    }
}
catch {
    Add-Check 'OnPremisesSynchronization' Warn "Could not read directory/onPremisesSynchronization: $($_.Exception.Message)"
}

$domains = Get-GraphCollection -Uri 'v1.0/domains?$select=id,authenticationType,isVerified,isDefault'
$federated = @($domains | Where-Object { $_.authenticationType -eq 'Federated' })
$domainDetail = ($domains | ForEach-Object { "$($_.id)=$($_.authenticationType)" }) -join '; '
Add-Check 'DomainAuthentication' $(if ($federated.Count -gt 0) { 'Warn' } else { 'Pass' }) $domainDetail

$syncedUserCount = $null
try {
    $syncedUserCount = Invoke-MgGraphRequest -Method GET -Headers @{ ConsistencyLevel = 'eventual' } `
        -Uri 'v1.0/users/$count?$filter=onPremisesSyncEnabled eq true'
}
catch {
    Write-Verbose "User count unavailable: $($_.Exception.Message)"
}

$errorUsers = 0
if ($UserSampleSize -gt 0) {
    $sample = Get-GraphCollection -Limit $UserSampleSize -Headers @{ ConsistencyLevel = 'eventual' } `
        -Uri 'v1.0/users?$filter=onPremisesSyncEnabled eq true&$count=true&$top=999&$select=id,onPremisesProvisioningErrors'
    $errorUsers = @($sample | Where-Object { $_.onPremisesProvisioningErrors -and @($_.onPremisesProvisioningErrors).Count -gt 0 }).Count
    $status = if ($errorUsers -eq 0) { 'Pass' } else { 'Warn' }
    Add-Check 'ProvisioningErrors' $status "$errorUsers of $($sample.Count) sampled synced users have provisioning errors."
}

$result = [pscustomobject]@{
    ReportTimeUtc    = $now.ToString('o')
    Tenant           = $org.displayName
    SyncedUsers      = $syncedUserCount
    FederatedDomains = @($federated | ForEach-Object { $_.id })
    Healthy          = -not ($checks | Where-Object Status -EQ 'Fail')
    Checks           = $checks
}

if ($OutputPath -and $PSCmdlet.ShouldProcess($OutputPath, 'Write sync health report')) {
    $result | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding utf8
}

$checks | Format-Table -AutoSize | Out-String | Write-Information -InformationAction Continue
$result
if (-not $result.Healthy) { $global:LASTEXITCODE = 1 }
