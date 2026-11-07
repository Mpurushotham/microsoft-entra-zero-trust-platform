#Requires -Version 7.2
#Requires -Modules @{ ModuleName = 'Microsoft.Graph.Authentication'; ModuleVersion = '2.0.0' }

<#
.SYNOPSIS
    Reports Intune device compliance and stale check-ins, optionally failing a pipeline.

.DESCRIPTION
    Read-only. Pulls managed devices and the tenant compliance summary from Microsoft Graph,
    groups them by platform and compliance state, flags devices that have not synced within
    -StaleDays and returns a summary object. With -FailThresholdPercent the script exits
    with code 1 when the noncompliant share exceeds the threshold, so it can gate a rollout
    stage in CI.

    User principal names are omitted unless -IncludeUserPrincipalName is set.

    Required Graph permission: DeviceManagementManagedDevices.Read.All.

.PARAMETER OperatingSystem
    Limit the report to these platforms (Windows, macOS, iOS, Android).

.PARAMETER StaleDays
    Devices whose last sync is older than this are reported as stale.

.PARAMETER OutputPath
    Optional CSV path for the per-device detail.

.PARAMETER FailThresholdPercent
    Exit with code 1 when noncompliant devices exceed this percentage.

.PARAMETER IncludeUserPrincipalName
    Include the primary user's UPN in the per-device output.

.PARAMETER TenantId
    Tenant to connect to when no Graph context exists.

.EXAMPLE
    .\Test-IntuneCompliance.ps1 -OperatingSystem Windows -StaleDays 14

.EXAMPLE
    .\Test-IntuneCompliance.ps1 -OutputPath .\compliance.csv -FailThresholdPercent 5

.NOTES
    Author: Purushotham Muktha
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('Windows', 'macOS', 'iOS', 'Android')]
    [string[]] $OperatingSystem,

    [ValidateRange(1, 365)]
    [int] $StaleDays = 30,

    [string] $OutputPath,

    [ValidateRange(0, 100)]
    [double] $FailThresholdPercent,

    [switch] $IncludeUserPrincipalName,

    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $TenantId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$graphBase = 'https://graph.microsoft.com/v1.0/deviceManagement'

function Get-GraphCollection {
    [CmdletBinding()]
    [OutputType([object[]])]
    param([Parameter(Mandatory)][string] $Uri)

    $items = [System.Collections.Generic.List[object]]::new()
    $next = $Uri
    while ($next) {
        $page = Invoke-MgGraphRequest -Method GET -Uri $next
        foreach ($value in $page.value) { $items.Add($value) }
        $next = $page.'@odata.nextLink'
    }
    $items.ToArray()
}

if (-not (Get-MgContext)) {
    $connect = @{ Scopes = 'DeviceManagementManagedDevices.Read.All'; NoWelcome = $true }
    if ($TenantId) { $connect.TenantId = $TenantId }
    Connect-MgGraph @connect
}

$select = 'id,deviceName,operatingSystem,osVersion,complianceState,lastSyncDateTime,managedDeviceOwnerType,azureADDeviceId,userPrincipalName'
$devices = Get-GraphCollection -Uri "$graphBase/managedDevices?`$select=$select&`$top=999"

if ($OperatingSystem) {
    $devices = $devices | Where-Object { $os = $_.operatingSystem; $OperatingSystem | Where-Object { $os -like "$_*" } }
}

$staleBefore = (Get-Date).ToUniversalTime().AddDays(-$StaleDays)
$detail = foreach ($device in $devices) {
    $lastSync = [datetime]$device.lastSyncDateTime
    $row = [ordered]@{
        DeviceName      = $device.deviceName
        OperatingSystem = $device.operatingSystem
        OsVersion       = $device.osVersion
        Ownership       = $device.managedDeviceOwnerType
        ComplianceState = $device.complianceState
        LastSyncUtc     = $lastSync.ToString('u')
        Stale           = $lastSync -lt $staleBefore
        EntraDeviceId   = $device.azureADDeviceId
    }
    if ($IncludeUserPrincipalName) { $row.UserPrincipalName = $device.userPrincipalName }
    [pscustomobject]$row
}

$total = @($detail).Count
$noncompliant = @($detail | Where-Object ComplianceState -In 'noncompliant', 'conflict', 'error').Count
$noncompliantPercent = if ($total) { [math]::Round(100 * $noncompliant / $total, 2) } else { 0 }

$tenantSummary = Invoke-MgGraphRequest -Method GET -Uri "$graphBase/deviceCompliancePolicyDeviceStateSummary"

$summary = [pscustomobject]@{
    ReportTimeUtc        = (Get-Date).ToUniversalTime().ToString('u')
    Devices              = $total
    Noncompliant         = $noncompliant
    NoncompliantPercent  = $noncompliantPercent
    Stale                = @($detail | Where-Object Stale).Count
    InGracePeriod        = @($detail | Where-Object ComplianceState -EQ 'inGracePeriod').Count
    ByPlatformAndState   = $detail | Group-Object OperatingSystem, ComplianceState -NoElement |
        Sort-Object Name | Select-Object @{ n = 'PlatformState'; e = { $_.Name } }, Count
    TenantPolicySummary  = [pscustomobject]@{
        Compliant    = $tenantSummary.compliantDeviceCount
        Noncompliant = $tenantSummary.nonCompliantDeviceCount
        InGrace      = $tenantSummary.inGracePeriodCount
        Error        = $tenantSummary.errorDeviceCount
        Conflict     = $tenantSummary.conflictDeviceCount
        Unknown      = $tenantSummary.unknownDeviceCount
    }
}

if ($OutputPath -and $PSCmdlet.ShouldProcess($OutputPath, 'Write per-device compliance CSV')) {
    $detail | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8
}

$summary

if ($PSBoundParameters.ContainsKey('FailThresholdPercent') -and $noncompliantPercent -gt $FailThresholdPercent) {
    Write-Error "Noncompliant devices at $noncompliantPercent% exceed the $FailThresholdPercent% threshold." -ErrorAction Continue
    exit 1
}
