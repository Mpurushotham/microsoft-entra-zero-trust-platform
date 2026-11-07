#Requires -Version 7.2
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Collects the Windows Autopilot hardware hash of the local device into an import CSV.

.DESCRIPTION
    Reads the 4K hardware hash from the MDM bridge WMI provider (MDM_DevDetail_Ext01) and the
    serial number from Win32_BIOS, then writes or appends a row in the format accepted by
    Intune and by Import-AutopilotDevices.ps1.

    Use -UseGetWindowsAutopilotInfo to delegate collection to the Microsoft-published
    Get-WindowsAutopilotInfo script from the PowerShell Gallery instead.

    Hardware hash collection is the fallback path. Prefer OEM or reseller registration
    (zero-touch) for new hardware; use this script for existing devices and pilots.

.PARAMETER OutputPath
    CSV file to create or append to.

.PARAMETER GroupTag
    Autopilot group tag (OrderID) that selects the deployment profile through the dynamic
    device groups created by stack 60-intune-autopilot-zero-touch, for example CORP-WIN.

.PARAMETER AssignedUser
    Optional user principal name to pre-assign for a personalised OOBE.

.PARAMETER UseGetWindowsAutopilotInfo
    Install (if needed) and run Get-WindowsAutopilotInfo instead of querying WMI directly.

.EXAMPLE
    .\Get-AutopilotHardwareHash.ps1 -OutputPath D:\autopilot\devices.csv -GroupTag CORP-WIN

.EXAMPLE
    .\Get-AutopilotHardwareHash.ps1 -OutputPath .\devices.csv -GroupTag KIOSK -WhatIf

.NOTES
    Author: Purushotham Muktha
    Must run elevated on the device itself, either in full Windows or from OOBE (Shift+F10).
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $OutputPath,

    [ValidatePattern('^[A-Z0-9-]{1,32}$')]
    [string] $GroupTag,

    [ValidatePattern('^[^@\s]+@[^@\s]+\.[^@\s]+$')]
    [string] $AssignedUser,

    [switch] $UseGetWindowsAutopilotInfo
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-HardwareIdentity {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $devDetail = Get-CimInstance -Namespace 'root/cimv2/mdm/dmmap' -ClassName 'MDM_DevDetail_Ext01' `
        -Filter "InstanceID='Ext' AND ParentID='./DevDetail'"
    if (-not $devDetail -or [string]::IsNullOrWhiteSpace($devDetail.DeviceHardwareData)) {
        throw 'MDM_DevDetail_Ext01 returned no hardware hash. Run elevated on a physical or TPM-enabled virtual device.'
    }

    $serial = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
    if ([string]::IsNullOrWhiteSpace($serial)) {
        throw 'Win32_BIOS returned no serial number; Autopilot requires one.'
    }

    [pscustomobject]@{
        'Device Serial Number' = $serial.Trim()
        'Windows Product ID'   = ''
        'Hardware Hash'        = $devDetail.DeviceHardwareData
        'Group Tag'            = $GroupTag
        'Assigned User'        = $AssignedUser
    }
}

$resolvedPath = [System.IO.Path]::GetFullPath($OutputPath)

if ($UseGetWindowsAutopilotInfo) {
    if (-not (Get-Command -Name Get-WindowsAutopilotInfo -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess('Get-WindowsAutopilotInfo', 'Install-Script from PowerShell Gallery (CurrentUser)')) {
            Install-Script -Name Get-WindowsAutopilotInfo -Scope CurrentUser -Force
        }
    }

    $arguments = @{ OutputFile = $resolvedPath; Append = $true }
    if ($GroupTag) { $arguments.GroupTag = $GroupTag }
    if ($AssignedUser) { $arguments.AssignedUser = $AssignedUser }

    if ($PSCmdlet.ShouldProcess($resolvedPath, 'Append hardware hash via Get-WindowsAutopilotInfo')) {
        Get-WindowsAutopilotInfo @arguments
    }
    return
}

$identity = Get-HardwareIdentity

if (Test-Path -LiteralPath $resolvedPath) {
    $existing = Import-Csv -LiteralPath $resolvedPath
    if ($existing.'Device Serial Number' -contains $identity.'Device Serial Number') {
        Write-Warning "Serial $($identity.'Device Serial Number') is already present in $resolvedPath; skipping."
        return
    }
}

if ($PSCmdlet.ShouldProcess($resolvedPath, "Write hardware hash for serial $($identity.'Device Serial Number')")) {
    $directory = Split-Path -Path $resolvedPath -Parent
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    $identity | Export-Csv -LiteralPath $resolvedPath -NoTypeInformation -Append -Encoding utf8
    Write-Verbose "Hardware hash for $($identity.'Device Serial Number') written to $resolvedPath."
}

[pscustomobject]@{
    SerialNumber = $identity.'Device Serial Number'
    GroupTag     = $GroupTag
    OutputPath   = $resolvedPath
}
