#Requires -Version 7.2
#Requires -Modules @{ ModuleName = 'Microsoft.Graph.Authentication'; ModuleVersion = '2.0.0' }

<#
.SYNOPSIS
    Imports Windows Autopilot devices from a hardware hash CSV through Microsoft Graph.

.DESCRIPTION
    Posts each CSV row to deviceManagement/importedWindowsAutopilotDeviceIdentities, polls
    until Intune finishes processing, removes the transient import records and triggers an
    Autopilot sync. The group tag is written to the device's OrderID, which the dynamic
    groups in stack 60-intune-autopilot-zero-touch use to pick the deployment profile:

        (device.devicePhysicalIds -any (_ -eq "[OrderID]:CORP-WIN"))

    Required Graph permission: DeviceManagementServiceConfig.ReadWrite.All (delegated or
    application). Authentication is left to Connect-MgGraph so no secret is handled here.

.PARAMETER CsvPath
    CSV with the columns Device Serial Number, Windows Product ID, Hardware Hash and
    optionally Group Tag and Assigned User (output of Get-AutopilotHardwareHash.ps1 or an OEM).

.PARAMETER GroupTag
    Overrides the Group Tag column for every row.

.PARAMETER TenantId
    Tenant to connect to when no Graph context exists.

.PARAMETER TimeoutMinutes
    Maximum time to wait for Intune to process the batch.

.PARAMETER SkipSync
    Do not trigger windowsAutopilotSettings/sync after the import.

.EXAMPLE
    .\Import-AutopilotDevices.ps1 -CsvPath .\devices.csv -GroupTag CORP-WIN -WhatIf

.EXAMPLE
    Connect-MgGraph -Scopes DeviceManagementServiceConfig.ReadWrite.All
    .\Import-AutopilotDevices.ps1 -CsvPath .\devices.csv -Verbose | Format-Table

.NOTES
    Author: Purushotham Muktha
    Devices already registered in another tenant fail with ZtdDeviceAssignedToOtherTenant;
    the previous owner or OEM must deregister them first.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
    [string] $CsvPath,

    [ValidatePattern('^[A-Z0-9-]{1,32}$')]
    [string] $GroupTag,

    [ValidatePattern('^[0-9a-fA-F-]{36}$')]
    [string] $TenantId,

    [ValidateRange(5, 120)]
    [int] $TimeoutMinutes = 30,

    [switch] $SkipSync
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$graphBase = 'https://graph.microsoft.com/v1.0/deviceManagement'
$requiredScope = 'DeviceManagementServiceConfig.ReadWrite.All'

function Connect-GraphIfNeeded {
    [CmdletBinding()]
    param()

    $context = Get-MgContext
    if ($context) {
        Write-Verbose "Using Graph context for tenant $($context.TenantId) as $($context.Account ?? $context.AppName)."
        return
    }
    $connect = @{ Scopes = $requiredScope; NoWelcome = $true }
    if ($TenantId) { $connect.TenantId = $TenantId }
    Connect-MgGraph @connect
}

$rows = Import-Csv -LiteralPath $CsvPath
$requiredColumns = 'Device Serial Number', 'Hardware Hash'
$columns = $rows | Select-Object -First 1 | ForEach-Object { $_.PSObject.Properties.Name }
foreach ($column in $requiredColumns) {
    if ($columns -notcontains $column) {
        throw "CSV is missing the '$column' column."
    }
}

$duplicates = $rows | Group-Object -Property 'Device Serial Number' | Where-Object Count -GT 1
if ($duplicates) {
    throw "Duplicate serial numbers in CSV: $($duplicates.Name -join ', ')"
}

if ($WhatIfPreference) {
    foreach ($row in $rows) {
        $tag = if ($GroupTag) { $GroupTag } elseif ($columns -contains 'Group Tag') { $row.'Group Tag' } else { '' }
        $null = $PSCmdlet.ShouldProcess($row.'Device Serial Number', "Import Autopilot device with group tag '$tag'")
    }
    return
}

Connect-GraphIfNeeded

$submitted = [System.Collections.Generic.List[object]]::new()
foreach ($row in $rows) {
    $serial = $row.'Device Serial Number'.Trim()
    $tag = if ($GroupTag) { $GroupTag } elseif ($columns -contains 'Group Tag') { $row.'Group Tag' } else { '' }
    $user = if ($columns -contains 'Assigned User') { $row.'Assigned User' } else { '' }

    if (-not $PSCmdlet.ShouldProcess($serial, "Import Autopilot device with group tag '$tag'")) {
        continue
    }

    $body = @{
        '@odata.type'             = '#microsoft.graph.importedWindowsAutopilotDeviceIdentity'
        serialNumber              = $serial
        productKey                = if ($columns -contains 'Windows Product ID') { $row.'Windows Product ID' } else { '' }
        hardwareIdentifier        = $row.'Hardware Hash'
        groupTag                  = $tag
        assignedUserPrincipalName = $user
        state                     = @{
            deviceImportStatus   = 'pending'
            deviceRegistrationId = ''
            deviceErrorCode      = 0
            deviceErrorName      = ''
        }
    } | ConvertTo-Json -Depth 5

    $created = Invoke-MgGraphRequest -Method POST -Uri "$graphBase/importedWindowsAutopilotDeviceIdentities" `
        -Body $body -ContentType 'application/json'
    $submitted.Add([pscustomobject]@{ Id = $created.id; SerialNumber = $serial; GroupTag = $tag })
    Write-Verbose "Submitted $serial (import id $($created.id))."
}

if ($submitted.Count -eq 0) {
    return
}

$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
$results = @{}
do {
    Start-Sleep -Seconds 30
    foreach ($item in $submitted | Where-Object { -not $results.ContainsKey($_.Id) }) {
        $state = (Invoke-MgGraphRequest -Method GET -Uri "$graphBase/importedWindowsAutopilotDeviceIdentities/$($item.Id)").state
        if ($state.deviceImportStatus -in 'complete', 'error') {
            $results[$item.Id] = [pscustomobject]@{
                SerialNumber = $item.SerialNumber
                GroupTag     = $item.GroupTag
                Status       = $state.deviceImportStatus
                ErrorName    = $state.deviceErrorName
                ErrorCode    = $state.deviceErrorCode
            }
        }
    }
    Write-Verbose "$($results.Count) of $($submitted.Count) devices processed."
} while ($results.Count -lt $submitted.Count -and (Get-Date) -lt $deadline)

foreach ($item in $submitted) {
    if (-not $results.ContainsKey($item.Id)) {
        $results[$item.Id] = [pscustomobject]@{
            SerialNumber = $item.SerialNumber
            GroupTag     = $item.GroupTag
            Status       = 'timeout'
            ErrorName    = ''
            ErrorCode    = 0
        }
        continue
    }
    # Import records are transient; leaving them blocks re-importing the same serial later.
    Invoke-MgGraphRequest -Method DELETE -Uri "$graphBase/importedWindowsAutopilotDeviceIdentities/$($item.Id)" | Out-Null
}

if (-not $SkipSync -and $PSCmdlet.ShouldProcess('windowsAutopilotSettings', 'Trigger Autopilot sync')) {
    try {
        Invoke-MgGraphRequest -Method POST -Uri "$graphBase/windowsAutopilotSettings/sync" | Out-Null
    }
    catch {
        # Intune throttles sync to once every 10 minutes; a 429 here is not an import failure.
        Write-Warning "Autopilot sync was not triggered: $($_.Exception.Message)"
    }
}

$results.Values | Sort-Object SerialNumber
