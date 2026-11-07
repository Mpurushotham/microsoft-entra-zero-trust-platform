#Requires -Version 7.2
#Requires -Modules Microsoft.Graph.Authentication

<#
.SYNOPSIS
    Reports Microsoft Entra hybrid joined, Entra joined and registered devices and their readiness
    to move to Entra join.

.DESCRIPTION
    Reads device objects from Microsoft Graph and classifies each Windows device:

      trustType ServerAd   Microsoft Entra hybrid joined (or pending registration when it has
                           never signed in)
      trustType AzureAd    Microsoft Entra joined
      trustType Workplace  Microsoft Entra registered

    Hybrid joined devices do not change join type in place. They move to Entra join by
    re-provisioning: wipe (or Fresh Start), then Windows Autopilot user-driven Entra join.
    Autopilot Reset keeps the existing join type, so it only applies after a device is already
    Entra joined. The report flags hybrid devices that already carry an Autopilot ZTDID (ready to
    re-provision) and those that need their hardware hash imported first
    (scripts/intune in this repository).

    With -IncludeIntune, the Intune managed device record is joined to show compliance and
    management agent.

.PARAMETER StaleDays
    Days since the last sign-in after which a device is flagged stale.

.PARAMETER IncludeIntune
    Join Intune managed device data (needs DeviceManagementManagedDevices.Read.All).

.PARAMETER OutputPath
    Folder for devices.csv and summary.json.

.EXAMPLE
    ./Get-DeviceJoinStateReport.ps1 -IncludeIntune -OutputPath ./out/devices

.NOTES
    Author: Purushotham Muktha
    Graph scopes: Device.Read.All, and DeviceManagementManagedDevices.Read.All with -IncludeIntune.
    Reference: https://learn.microsoft.com/entra/identity/devices/hybrid-join-to-entra-join
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateRange(14, 3650)]
    [int] $StaleDays = 90,

    [switch] $IncludeIntune,

    [string] $OutputPath = (Join-Path -Path (Get-Location) -ChildPath "device-join-$(Get-Date -Format yyyyMMdd-HHmmss)")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scopes = @('Device.Read.All')
if ($IncludeIntune) { $scopes += 'DeviceManagementManagedDevices.Read.All' }
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

$select = 'id,deviceId,displayName,operatingSystem,operatingSystemVersion,trustType,profileType,isManaged,isCompliant,accountEnabled,onPremisesSyncEnabled,approximateLastSignInDateTime,registrationDateTime,physicalIds'
$devices = Get-GraphCollection -Uri "v1.0/devices?`$select=$select&`$top=999"

$intune = @{}
if ($IncludeIntune) {
    foreach ($md in Get-GraphCollection -Uri 'v1.0/deviceManagement/managedDevices?$select=azureADDeviceId,complianceState,managementAgent,joinType,lastSyncDateTime,autopilotEnrolled') {
        if ($md.azureADDeviceId) { $intune[[string]$md.azureADDeviceId] = $md }
    }
}

$staleCutoff = [datetime]::UtcNow.AddDays(-$StaleDays)

$rows = foreach ($d in $devices) {
    $lastSignIn = if ($d.approximateLastSignInDateTime) { ([datetime]$d.approximateLastSignInDateTime).ToUniversalTime() } else { $null }
    $hasZtdId = [bool](@($d.physicalIds) | Where-Object { $_ -like '`[ZTDID`]*' })

    $joinState = switch ($d.trustType) {
        'ServerAd' { if ($lastSignIn) { 'HybridJoined' } else { 'HybridPending' } }
        'AzureAd' { 'EntraJoined' }
        'Workplace' { 'EntraRegistered' }
        default { 'Unknown' }
    }

    $isWindowsDevice = $d.operatingSystem -like 'Windows*'
    $stale = (-not $lastSignIn) -or ($lastSignIn -lt $staleCutoff)
    $readiness = if (-not $isWindowsDevice -or $joinState -in @('EntraJoined', 'EntraRegistered')) {
        'NotApplicable'
    }
    elseif ($stale) {
        'StaleRetire'
    }
    elseif ($hasZtdId) {
        'ReadyToReprovision'
    }
    else {
        'ImportAutopilotHash'
    }

    $md = $intune[[string]$d.deviceId]
    [pscustomobject]@{
        DisplayName       = $d.displayName
        DeviceId          = $d.deviceId
        OperatingSystem   = $d.operatingSystem
        OsVersion         = $d.operatingSystemVersion
        JoinState         = $joinState
        AccountEnabled    = $d.accountEnabled
        SyncedFromAD      = [bool]$d.onPremisesSyncEnabled
        IsManaged         = $d.isManaged
        IsCompliant       = $d.isCompliant
        AutopilotZtdId    = $hasZtdId
        LastSignInUtc     = $lastSignIn
        Stale             = $stale
        MigrationAction   = $readiness
        IntuneCompliance  = if ($md) { $md.complianceState } else { $null }
        IntuneAgent       = if ($md) { $md.managementAgent } else { $null }
    }
}
$rows = @($rows)

$summary = [ordered]@{
    reportTimeUtc = [datetime]::UtcNow.ToString('o')
    totalDevices = $rows.Count
    byJoinState  = [ordered]@{}
    windowsByMigrationAction = [ordered]@{}
    entraJoinedPercentOfWindows = 0
}
$rows | Group-Object JoinState | ForEach-Object { $summary.byJoinState[$_.Name] = $_.Count }
$windows = @($rows | Where-Object { $_.OperatingSystem -like 'Windows*' -and $_.JoinState -ne 'EntraRegistered' })
$windows | Group-Object MigrationAction | ForEach-Object { $summary.windowsByMigrationAction[$_.Name] = $_.Count }
if ($windows.Count -gt 0) {
    $summary.entraJoinedPercentOfWindows = [math]::Round(100 * @($windows | Where-Object JoinState -EQ 'EntraJoined').Count / $windows.Count, 1)
}

if ($PSCmdlet.ShouldProcess($OutputPath, 'Write device join report')) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    $rows | Export-Csv -Path (Join-Path $OutputPath 'devices.csv') -NoTypeInformation -Encoding utf8
    $summary | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $OutputPath 'summary.json') -Encoding utf8
}

[pscustomobject]$summary
