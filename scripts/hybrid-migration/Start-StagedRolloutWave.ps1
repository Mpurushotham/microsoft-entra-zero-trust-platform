#Requires -Version 7.2
#Requires -Modules Microsoft.Graph.Authentication

<#
.SYNOPSIS
    Adds a migration wave of users to its staged rollout group and validates the result.

.DESCRIPTION
    Moves a wave of synced, federated users to cloud authentication through Microsoft Entra
    staged rollout. The wave group and feature rollout policies are created by
    terraform/stacks/40-hybrid-migration; this script manages membership only.

    For every user in the input file the script checks that the account exists, is enabled, is
    synchronized from AD (onPremisesSyncEnabled), sits on a federated domain, and is not already in
    another wave. Valid users are added in batches of 20 (the Graph members@odata.bind limit).

    If the wave group is not yet attached to a feature rollout policy, at most 200 members are
    allowed, because Entra rejects attaching a group with more on first use. Attach the wave with
    Terraform (enabled_waves) and run again to add the rest.

.PARAMETER Wave
    Wave name, matching the Terraform migration_waves value.

.PARAMETER UserListPath
    CSV file with a UserPrincipalName column.

.PARAMETER NamePrefix
    Terraform name_prefix.

.PARAMETER Environment
    Terraform environment.

.PARAMETER GroupDisplayName
    Overrides the derived group name <prefix>-<env>-hybrid-wave-<wave>.

.PARAMETER OutputPath
    Folder for the validation report.

.EXAMPLE
    ./Start-StagedRolloutWave.ps1 -Wave pilot -Environment dev -UserListPath ./waves/pilot.csv -WhatIf

.EXAMPLE
    ./Start-StagedRolloutWave.ps1 -Wave wave1 -Environment prod -UserListPath ./waves/wave1.csv -Confirm:$false

.NOTES
    Author: Purushotham Muktha
    Graph scopes: GroupMember.ReadWrite.All, User.Read.All, Domain.Read.All, Directory.Read.All.
    Users fall back to federation as soon as they are removed from the group (Invoke-MigrationRollback.ps1).
    Reference: https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-staged-rollout
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-z0-9-]{2,20}$')]
    [string] $Wave,

    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string] $UserListPath,

    [ValidatePattern('^[a-z][a-z0-9]{1,9}$')]
    [string] $NamePrefix = 'zt',

    [Parameter(Mandatory)]
    [ValidateSet('dev', 'prod')]
    [string] $Environment,

    [string] $GroupDisplayName,

    [string] $OutputPath = (Join-Path -Path (Get-Location) -ChildPath "wave-$Wave-$(Get-Date -Format yyyyMMdd-HHmmss)")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$firstAttachLimit = 200
$bindBatchSize = 20

$scopes = @('GroupMember.ReadWrite.All', 'User.Read.All', 'Domain.Read.All', 'Directory.Read.All')
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes -NoWelcome }

function Get-GraphCollection {
    param([Parameter(Mandatory)] [string] $Uri, [hashtable] $Headers = @{})
    $items = [System.Collections.Generic.List[object]]::new()
    $next = $Uri
    while ($next) {
        $page = Invoke-MgGraphRequest -Method GET -Uri $next -Headers $Headers
        foreach ($v in @($page.value)) { $items.Add($v) }
        $next = $page.'@odata.nextLink'
    }
    return $items
}

function Get-WaveGroup {
    param([Parameter(Mandatory)] [string] $DisplayName)
    $escaped = $DisplayName.Replace("'", "''")
    $found = @(Get-GraphCollection -Uri "v1.0/groups?`$filter=displayName eq '$escaped'&`$select=id,displayName,groupTypes,membershipRule")
    if ($found.Count -ne 1) { throw "Expected exactly one group named '$DisplayName', found $($found.Count). Apply terraform/stacks/40-hybrid-migration first." }
    if (@($found[0].groupTypes) -contains 'DynamicMembership') { throw "'$DisplayName' is dynamic; staged rollout supports assigned groups only." }
    return $found[0]
}

if (-not $GroupDisplayName) { $GroupDisplayName = "$NamePrefix-$Environment-hybrid-wave-$Wave" }
$group = Get-WaveGroup -DisplayName $GroupDisplayName

$federatedDomains = @(Get-GraphCollection -Uri 'v1.0/domains?$select=id,authenticationType' |
        Where-Object { $_.authenticationType -eq 'Federated' } | ForEach-Object { $_.id.ToLowerInvariant() })
if ($federatedDomains.Count -eq 0) {
    Write-Warning 'No federated domains remain. Staged rollout has no effect on managed domains.'
}

$policies = @(Get-GraphCollection -Uri 'v1.0/policies/featureRolloutPolicies?$expand=appliesTo')
$attachedFeatures = @($policies | Where-Object { @($_.appliesTo | ForEach-Object { $_.id }) -contains $group.id } | ForEach-Object { $_.feature })
$isAttached = $attachedFeatures.Count -gt 0
if (-not ($attachedFeatures -contains 'passwordHashSync' -or $attachedFeatures -contains 'passthroughAuthentication')) {
    Write-Warning "$GroupDisplayName is not attached to a passwordHashSync or passthroughAuthentication rollout policy yet."
}

$existingMembers = @(Get-GraphCollection -Uri "v1.0/groups/$($group.id)/members/microsoft.graph.user?`$select=id")
$existingIds = [System.Collections.Generic.HashSet[string]]::new([string[]]@($existingMembers | ForEach-Object { $_.id }))

$otherWaveMembers = [System.Collections.Generic.Dictionary[string, string]]::new()
$wavePrefix = "$NamePrefix-$Environment-hybrid-wave-"
$otherWaves = @(Get-GraphCollection -Uri "v1.0/groups?`$filter=startswith(displayName,'$wavePrefix')&`$select=id,displayName" |
        Where-Object { $_.id -ne $group.id })
foreach ($other in $otherWaves) {
    foreach ($m in Get-GraphCollection -Uri "v1.0/groups/$($other.id)/members/microsoft.graph.user?`$select=id") {
        $otherWaveMembers[$m.id] = $other.displayName
    }
}

$requested = @(Import-Csv -Path $UserListPath | ForEach-Object { $_.UserPrincipalName } | Where-Object { $_ } | Sort-Object -Unique)
if ($requested.Count -eq 0) { throw "$UserListPath has no UserPrincipalName values." }

$validation = [System.Collections.Generic.List[pscustomobject]]::new()
$toAdd = [System.Collections.Generic.List[string]]::new()

foreach ($upn in $requested) {
    $status = 'Valid'
    $reason = ''
    $user = $null
    try {
        $user = Invoke-MgGraphRequest -Method GET -Uri "v1.0/users/$([uri]::EscapeDataString($upn))?`$select=id,userPrincipalName,accountEnabled,onPremisesSyncEnabled"
    }
    catch {
        $status = 'Rejected'; $reason = 'NotFound'
    }

    if ($user) {
        $domain = $upn.Split('@')[-1].ToLowerInvariant()
        if (-not $user.accountEnabled) { $status = 'Rejected'; $reason = 'Disabled' }
        elseif (-not $user.onPremisesSyncEnabled) { $status = 'Rejected'; $reason = 'CloudOnly' }
        elseif ($federatedDomains.Count -gt 0 -and $domain -notin $federatedDomains) { $status = 'Rejected'; $reason = 'DomainNotFederated' }
        elseif ($otherWaveMembers.ContainsKey($user.id)) { $status = 'Rejected'; $reason = "InOtherWave:$($otherWaveMembers[$user.id])" }
        elseif ($existingIds.Contains($user.id)) { $status = 'Skipped'; $reason = 'AlreadyMember' }
        else { $toAdd.Add($user.id) }
    }

    $validation.Add([pscustomobject]@{ UserPrincipalName = $upn; Status = $status; Reason = $reason })
}

$capacity = if ($isAttached) { [int]::MaxValue } else { [math]::Max(0, $firstAttachLimit - $existingIds.Count) }
$deferred = @()
if ($toAdd.Count -gt $capacity) {
    $deferred = $toAdd.GetRange($capacity, $toAdd.Count - $capacity).ToArray()
    $toAdd = $toAdd.GetRange(0, $capacity)
    Write-Warning "$($deferred.Count) users deferred: the group is not attached yet and the first attachment is limited to $firstAttachLimit members."
}

$added = 0
for ($i = 0; $i -lt $toAdd.Count; $i += $bindBatchSize) {
    $batch = $toAdd.GetRange($i, [math]::Min($bindBatchSize, $toAdd.Count - $i))
    if ($PSCmdlet.ShouldProcess("$GroupDisplayName", "Add $($batch.Count) users")) {
        $body = @{ 'members@odata.bind' = @($batch | ForEach-Object { "https://graph.microsoft.com/v1.0/directoryObjects/$_" }) }
        Invoke-MgGraphRequest -Method PATCH -Uri "v1.0/groups/$($group.id)" -Body ($body | ConvertTo-Json -Depth 3) -ContentType 'application/json' | Out-Null
        $added += $batch.Count
    }
}

$memberCount = Invoke-MgGraphRequest -Method GET -Headers @{ ConsistencyLevel = 'eventual' } -Uri "v1.0/groups/$($group.id)/members/`$count"

$summary = [pscustomobject]@{
    Wave             = $Wave
    Group            = $GroupDisplayName
    AttachedFeatures = $attachedFeatures
    Requested        = $requested.Count
    Added            = $added
    Deferred         = $deferred.Count
    Rejected         = @($validation | Where-Object Status -EQ 'Rejected').Count
    MemberCount      = $memberCount
}

if ($PSCmdlet.ShouldProcess($OutputPath, 'Write wave validation report')) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    $validation | Export-Csv -Path (Join-Path $OutputPath 'validation.csv') -NoTypeInformation -Encoding utf8
    $summary | ConvertTo-Json -Depth 3 | Set-Content -Path (Join-Path $OutputPath 'summary.json') -Encoding utf8
}

$summary
