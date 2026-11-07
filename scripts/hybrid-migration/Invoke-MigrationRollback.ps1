#Requires -Version 7.2
#Requires -Modules Microsoft.Graph.Authentication

<#
.SYNOPSIS
    Rolls back a stage of the AD FS to Microsoft Entra ID authentication migration.

.DESCRIPTION
    Three rollback actions, from narrowest to widest impact:

      RemoveWaveUsers       Removes users (or the whole wave) from a staged rollout group. Those
                            users return to AD FS sign-in on their next authentication.
      DisableStagedRollout  Sets isEnabled = false on feature rollout policies. All staged users
                            return to AD FS. Mirror it in Terraform with staged_rollout_enabled = false,
                            or the next apply re-enables the policies.
      RestoreFederation     Re-creates the federation configuration of a converted domain from the
                            backup written by Convert-DomainToManaged.ps1. The AD FS farm and its
                            token-signing certificate must be unchanged.

    The script runs in preview (WhatIf) mode unless -Execute is supplied.

.PARAMETER Action
    RemoveWaveUsers, DisableStagedRollout or RestoreFederation.

.PARAMETER Wave
    Wave to roll back (RemoveWaveUsers).

.PARAMETER UserListPath
    CSV with a UserPrincipalName column. When omitted, every member of the wave is removed.

.PARAMETER NamePrefix
    Terraform name_prefix.

.PARAMETER Environment
    Terraform environment.

.PARAMETER Feature
    Feature rollout policies to disable (DisableStagedRollout). Defaults to all.

.PARAMETER DomainName
    Domain to federate again (RestoreFederation).

.PARAMETER FederationBackupPath
    Backup JSON produced by Convert-DomainToManaged.ps1.

.PARAMETER Execute
    Applies the rollback. Without it the script reports what it would do.

.EXAMPLE
    ./Invoke-MigrationRollback.ps1 -Action RemoveWaveUsers -Wave wave1 -Environment prod -UserListPath ./affected.csv -Execute

.EXAMPLE
    ./Invoke-MigrationRollback.ps1 -Action DisableStagedRollout -Execute

.EXAMPLE
    ./Invoke-MigrationRollback.ps1 -Action RestoreFederation -DomainName contoso.com -FederationBackupPath ./federation-backup/contoso.com-federation-20260101-120000.json -Execute

.NOTES
    Author: Purushotham Muktha
    Graph scopes: GroupMember.ReadWrite.All, User.Read.All, Directory.ReadWrite.All, Domain.ReadWrite.All.
    Reference: https://learn.microsoft.com/entra/identity/hybrid/connect/migrate-from-federation-to-cloud-authentication#plan-for-rollback
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'Wave')]
param(
    [Parameter(Mandatory)]
    [ValidateSet('RemoveWaveUsers', 'DisableStagedRollout', 'RestoreFederation')]
    [string] $Action,

    [Parameter(ParameterSetName = 'Wave')]
    [ValidatePattern('^[a-z0-9-]{2,20}$')]
    [string] $Wave,

    [Parameter(ParameterSetName = 'Wave')]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string] $UserListPath,

    [Parameter(ParameterSetName = 'Wave')]
    [ValidatePattern('^[a-z][a-z0-9]{1,9}$')]
    [string] $NamePrefix = 'zt',

    [Parameter(ParameterSetName = 'Wave')]
    [ValidateSet('dev', 'prod')]
    [string] $Environment = 'dev',

    [Parameter(ParameterSetName = 'Policy')]
    [ValidateSet('passwordHashSync', 'passthroughAuthentication', 'seamlessSso', 'certificateBasedAuthentication', 'multiFactorAuthentication')]
    [string[]] $Feature,

    [Parameter(ParameterSetName = 'Federation', Mandatory)]
    [string] $DomainName,

    [Parameter(ParameterSetName = 'Federation', Mandatory)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string] $FederationBackupPath,

    [switch] $Execute
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $Execute) { $WhatIfPreference = $true }

$scopes = @('GroupMember.ReadWrite.All', 'User.Read.All', 'Directory.ReadWrite.All', 'Domain.ReadWrite.All')
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes -NoWelcome }

function Get-GraphCollection {
    param([Parameter(Mandatory)] [string] $Uri)
    $items = [System.Collections.Generic.List[object]]::new()
    $next = $Uri
    while ($next) {
        $page = Invoke-MgGraphRequest -Method GET -Uri $next
        foreach ($v in @($page.value)) { $items.Add($v) }
        $next = $page.'@odata.nextLink'
    }
    return $items
}

switch ($Action) {
    'RemoveWaveUsers' {
        if (-not $Wave) { throw '-Wave is required for RemoveWaveUsers.' }
        $groupName = "$NamePrefix-$Environment-hybrid-wave-$Wave"
        $group = @(Get-GraphCollection -Uri "v1.0/groups?`$filter=displayName eq '$groupName'&`$select=id,displayName")
        if ($group.Count -ne 1) { throw "Expected one group named $groupName, found $($group.Count)." }
        $groupId = $group[0].id

        $members = @(Get-GraphCollection -Uri "v1.0/groups/$groupId/members/microsoft.graph.user?`$select=id,userPrincipalName")
        $targets = if ($UserListPath) {
            $wanted = @(Import-Csv -Path $UserListPath | ForEach-Object { $_.UserPrincipalName.ToLowerInvariant() })
            @($members | Where-Object { $_.userPrincipalName.ToLowerInvariant() -in $wanted })
        }
        else {
            $members
        }

        $removed = 0
        foreach ($member in $targets) {
            if ($PSCmdlet.ShouldProcess($member.userPrincipalName, "Remove from $groupName")) {
                Invoke-MgGraphRequest -Method DELETE -Uri "v1.0/groups/$groupId/members/$($member.id)/`$ref" | Out-Null
                $removed++
            }
        }
        [pscustomobject]@{ Action = $Action; Group = $groupName; Targeted = @($targets).Count; Removed = $removed }
    }

    'DisableStagedRollout' {
        $policies = @(Get-GraphCollection -Uri 'v1.0/policies/featureRolloutPolicies')
        if ($Feature) { $policies = @($policies | Where-Object { $_.feature -in $Feature }) }
        $disabled = @()
        foreach ($policy in $policies | Where-Object { $_.isEnabled }) {
            if ($PSCmdlet.ShouldProcess("$($policy.displayName) ($($policy.feature))", 'Disable feature rollout policy')) {
                Invoke-MgGraphRequest -Method PATCH -Uri "v1.0/policies/featureRolloutPolicies/$($policy.id)" `
                    -Body (@{ isEnabled = $false } | ConvertTo-Json) -ContentType 'application/json' | Out-Null
                $disabled += $policy.feature
            }
        }
        Write-Warning 'Set staged_rollout_enabled = false in terraform/stacks/40-hybrid-migration tfvars so the next apply does not re-enable the policies.'
        [pscustomobject]@{ Action = $Action; Disabled = $disabled }
    }

    'RestoreFederation' {
        $domain = Invoke-MgGraphRequest -Method GET -Uri "v1.0/domains/$DomainName"
        if ($domain.authenticationType -eq 'Federated') { throw "$DomainName is already Federated." }

        $backup = Get-Content -Path $FederationBackupPath -Raw | ConvertFrom-Json -AsHashtable
        $allowed = @(
            'displayName', 'issuerUri', 'metadataExchangeUri', 'passiveSignInUri', 'activeSignInUri', 'signOutUri',
            'signingCertificate', 'nextSigningCertificate', 'preferredAuthenticationProtocol', 'promptLoginBehavior',
            'federatedIdpMfaBehavior', 'isSignedAuthenticationRequestRequired', 'passwordResetUri'
        )
        $body = @{}
        foreach ($key in $allowed) {
            if ($backup.ContainsKey($key) -and $null -ne $backup[$key]) { $body[$key] = $backup[$key] }
        }
        foreach ($required in 'issuerUri', 'passiveSignInUri', 'signingCertificate') {
            if (-not $body.ContainsKey($required)) { throw "Backup is missing $required; cannot restore federation." }
        }

        try {
            Invoke-WebRequest -Uri $body.passiveSignInUri -Method Head -TimeoutSec 15 -SkipHttpErrorCheck | Out-Null
        }
        catch {
            throw "AD FS endpoint $($body.passiveSignInUri) is unreachable. Restore AD FS before federating the domain again."
        }

        if ($PSCmdlet.ShouldProcess($DomainName, 'Restore federation configuration (Managed -> Federated)')) {
            Invoke-MgGraphRequest -Method POST -Uri "v1.0/domains/$DomainName/federationConfiguration" `
                -Body ($body | ConvertTo-Json -Depth 4) -ContentType 'application/json' | Out-Null
            $after = Invoke-MgGraphRequest -Method GET -Uri "v1.0/domains/$DomainName"
            Write-Information "$DomainName now reports $($after.authenticationType)." -InformationAction Continue
        }
        [pscustomobject]@{ Action = $Action; Domain = $DomainName; Backup = $FederationBackupPath; Executed = [bool]$Execute }
    }
}
