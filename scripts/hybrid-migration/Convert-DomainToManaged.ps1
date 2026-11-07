#Requires -Version 7.2
#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Identity.DirectoryManagement

<#
.SYNOPSIS
    Converts a federated domain in Microsoft Entra ID to managed (cloud) authentication.

.DESCRIPTION
    Final cutover from AD FS to password hash sync for one domain. The script runs in preview
    (WhatIf) mode unless -Execute is supplied.

    Prerequisite checks (all must pass, or the script stops):
      1. The domain exists and is Federated.
      2. The signed-in administrator is not on the domain being converted, so a cloud-only
         account keeps access if sign-in breaks.
      3. Password hash sync is enabled and has reported within MaxPasswordSyncAgeMinutes.
      4. A passwordHashSync staged rollout policy exists (warning only).
      5. The AD FS relying party inventory, when supplied, has no relying party still marked
         NotMigrated (warning only; apps on AD FS keep working only while AD FS stays up).

    The current federation configuration is exported to BackupPath before any change. That
    file is required by Invoke-MigrationRollback.ps1 -Action RestoreFederation.

    If Entra Connect Sync manages the AD FS farm, run "Change user sign-in" in the Connect wizard
    instead; it performs the same conversion and updates the Connect configuration to match.

.PARAMETER DomainName
    The federated domain to convert, for example contoso.com.

.PARAMETER Execute
    Performs the conversion. Without it the script reports what it would do.

.PARAMETER BackupPath
    Folder for the federation configuration backup.

.PARAMETER MaxPasswordSyncAgeMinutes
    Maximum age of the last password hash sync heartbeat.

.PARAMETER RelyingPartyInventoryPath
    Optional inventory.csv from Get-ADFSRelyingPartyInventory.ps1 annotated with a MigrationStatus column.

.EXAMPLE
    ./Convert-DomainToManaged.ps1 -DomainName contoso.com
    Runs all prechecks and shows the change without making it.

.EXAMPLE
    ./Convert-DomainToManaged.ps1 -DomainName contoso.com -Execute -BackupPath ./backup
    Converts the domain after confirmation.

.NOTES
    Author: Purushotham Muktha
    Graph scopes: Domain.ReadWrite.All, Directory.Read.All, Organization.Read.All, OnPremDirectorySynchronization.Read.All.
    Conversion propagates within minutes but allow up to 4 hours of change window.

    ROLLBACK (AD FS farm must still be running):
      ./Invoke-MigrationRollback.ps1 -Action RestoreFederation -DomainName contoso.com `
          -FederationBackupPath ./backup/contoso.com-federation-<timestamp>.json -Execute
    Equivalent manual Graph call: POST /domains/{domain}/federationConfiguration with the backup body.

    Reference: https://learn.microsoft.com/entra/identity/hybrid/connect/migrate-from-federation-to-cloud-authentication
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^(?!-)[A-Za-z0-9-]{1,63}(\.[A-Za-z0-9-]{1,63})+$')]
    [string] $DomainName,

    [switch] $Execute,

    [string] $BackupPath = (Join-Path -Path (Get-Location) -ChildPath 'federation-backup'),

    [ValidateRange(5, 1440)]
    [int] $MaxPasswordSyncAgeMinutes = 120,

    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string] $RelyingPartyInventoryPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Preview is the default: the conversion is tenant-wide for every user on the domain.
if (-not $Execute) { $WhatIfPreference = $true }

$scopes = @('Domain.ReadWrite.All', 'Directory.Read.All', 'Organization.Read.All', 'OnPremDirectorySynchronization.Read.All')
if (-not (Get-MgContext)) { Connect-MgGraph -Scopes $scopes -NoWelcome }

$failures = [System.Collections.Generic.List[string]]::new()

$domain = $null
try {
    $domain = Invoke-MgGraphRequest -Method GET -Uri "v1.0/domains/$DomainName"
}
catch {
    throw "Domain $DomainName was not found in the tenant."
}
if ($domain.authenticationType -ne 'Federated') {
    throw "Domain $DomainName is already $($domain.authenticationType); nothing to convert."
}
Write-Information "[ok] $DomainName is Federated." -InformationAction Continue

$account = (Get-MgContext).Account
if ($account -and $account.Split('@')[-1] -ieq $DomainName) {
    $failures.Add("Signed in as $account, which is on $DomainName. Use a cloud-only (onmicrosoft.com) administrator.")
}

$org = (Invoke-MgGraphRequest -Method GET -Uri 'v1.0/organization?$select=onPremisesSyncEnabled,onPremisesLastPasswordSyncDateTime').value | Select-Object -First 1
if (-not $org.onPremisesLastPasswordSyncDateTime) {
    $failures.Add('Password hash sync has never reported. Enable PHS and wait for the initial sync to complete.')
}
else {
    $age = [int]([datetime]::UtcNow - ([datetime]$org.onPremisesLastPasswordSyncDateTime).ToUniversalTime()).TotalMinutes
    if ($age -gt $MaxPasswordSyncAgeMinutes) { $failures.Add("Last password hash sync was $age minutes ago (limit $MaxPasswordSyncAgeMinutes).") }
    else { Write-Information "[ok] Password hash sync reported $age minutes ago." -InformationAction Continue }
}

try {
    $sync = (Invoke-MgGraphRequest -Method GET -Uri 'v1.0/directory/onPremisesSynchronization').value | Select-Object -First 1
    if (-not $sync.features.passwordSyncEnabled) { $failures.Add('directory/onPremisesSynchronization reports passwordSyncEnabled = false.') }
}
catch {
    Write-Warning "Could not read on-premises synchronization features: $($_.Exception.Message)"
}

$policies = @((Invoke-MgGraphRequest -Method GET -Uri 'v1.0/policies/featureRolloutPolicies').value)
if (-not ($policies | Where-Object { $_.feature -eq 'passwordHashSync' })) {
    Write-Warning 'No passwordHashSync staged rollout policy exists. Converting without a validated pilot is not recommended.'
}

if ($RelyingPartyInventoryPath) {
    $pending = @(Import-Csv -Path $RelyingPartyInventoryPath | Where-Object { $_.PSObject.Properties['MigrationStatus'] -and $_.MigrationStatus -eq 'NotMigrated' })
    if ($pending.Count -gt 0) {
        Write-Warning "$($pending.Count) relying parties are still NotMigrated. They keep using AD FS, which must stay online until they move."
    }
}

$federation = @((Invoke-MgGraphRequest -Method GET -Uri "v1.0/domains/$DomainName/federationConfiguration").value)
if ($federation.Count -eq 0) {
    $failures.Add("No federationConfiguration found for $DomainName; nothing to back up for rollback.")
}

$otherFederated = @((Invoke-MgGraphRequest -Method GET -Uri 'v1.0/domains?$select=id,authenticationType').value |
        Where-Object { $_.authenticationType -eq 'Federated' -and $_.id -ne $DomainName } | ForEach-Object { $_.id })
if ($otherFederated.Count -gt 0) {
    Write-Information "Other federated domains (unchanged by this run): $($otherFederated -join ', ')" -InformationAction Continue
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error -Message $_ -ErrorAction Continue }
    throw "Prerequisite checks failed for $DomainName. No change was made."
}

$timestamp = Get-Date -Format yyyyMMdd-HHmmss
$backupFile = Join-Path $BackupPath "$DomainName-federation-$timestamp.json"

# The backup is written even in preview so the rollback file exists before the change window.
New-Item -Path $BackupPath -ItemType Directory -Force -WhatIf:$false | Out-Null
$federation[0] | ConvertTo-Json -Depth 6 | Set-Content -Path $backupFile -Encoding utf8 -WhatIf:$false
Write-Information "[ok] Federation configuration backed up to $backupFile" -InformationAction Continue

if ($PSCmdlet.ShouldProcess($DomainName, 'Convert authentication from Federated to Managed')) {
    Update-MgDomain -DomainId $DomainName -BodyParameter @{ authenticationType = 'Managed' }

    $after = Invoke-MgGraphRequest -Method GET -Uri "v1.0/domains/$DomainName"
    if ($after.authenticationType -ne 'Managed') {
        throw "Domain still reports $($after.authenticationType). Investigate before retrying; rollback file: $backupFile"
    }
    Write-Information "[done] $DomainName is Managed." -InformationAction Continue
}

[pscustomobject]@{
    Domain       = $DomainName
    Executed     = [bool]$Execute
    BackupFile   = $backupFile
    RollbackHint = "./Invoke-MigrationRollback.ps1 -Action RestoreFederation -DomainName $DomainName -FederationBackupPath '$backupFile' -Execute"
    NextSteps    = @(
        'Test sign-in for a pilot user and a user who was never in staged rollout.'
        'Set staged_rollout_enabled = false in the 40-hybrid-migration tfvars once the domain is managed.'
        'Keep AD FS running for the rollback window, then decommission it (README phase 6).'
    )
}
