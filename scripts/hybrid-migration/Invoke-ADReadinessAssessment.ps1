#Requires -Version 7.2
#Requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Assesses Active Directory users and groups for synchronization to Microsoft Entra ID.

.DESCRIPTION
    Runs IdFix-style hygiene checks against AD DS before Entra Cloud Sync or Connect Sync is
    scoped to production OUs:

      - UPN present, suffix routable and (optionally) a verified Entra domain
      - characters Entra rejects in userPrincipalName, mailNickname and proxyAddresses
      - duplicate userPrincipalName, mail and proxyAddresses values across users and groups
      - attribute length limits
      - stale accounts (lastLogonTimestamp and pwdLastSet)
      - privileged accounts (adminCount = 1), which should not be synchronized; use
        cloud-only administrator accounts instead

    Writes findings.csv and summary.json to OutputPath. Read-only against AD.

.PARAMETER SearchBase
    Distinguished name of the OU to assess. Defaults to the domain root.

.PARAMETER Server
    Domain controller or domain to query.

.PARAMETER VerifiedDomain
    Domains verified in the Entra tenant. When supplied, any UPN suffix outside this list is
    reported as an error.

.PARAMETER StaleDays
    Days without logon or password change after which an enabled account is reported stale.

.PARAMETER IncludeDisabled
    Also assess disabled accounts.

.PARAMETER OutputPath
    Folder for the report. Created when missing.

.EXAMPLE
    ./Invoke-ADReadinessAssessment.ps1 -SearchBase 'OU=Staff,DC=contoso,DC=local' -VerifiedDomain contoso.com -OutputPath ./out/assessment

.EXAMPLE
    ./Invoke-ADReadinessAssessment.ps1 -Server dc01.contoso.local -StaleDays 60 -WhatIf

.NOTES
    Author: Purushotham Muktha
    Run from a domain-joined host with RSAT Active Directory tools. Requires read access only.
    Reference: https://learn.microsoft.com/entra/identity/hybrid/connect/how-to-connect-install-prerequisites
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $SearchBase,

    [string] $Server,

    [string[]] $VerifiedDomain = @(),

    [ValidateRange(14, 3650)]
    [int] $StaleDays = 90,

    [switch] $IncludeDisabled,

    [string] $OutputPath = (Join-Path -Path (Get-Location) -ChildPath "ad-readiness-$(Get-Date -Format yyyyMMdd-HHmmss)")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# UPN prefixes may contain only letters, digits and ' . - _ ! # ^ ~ (IdFix rule set).
$upnInvalidPattern = "[^A-Za-z0-9'._!#^~-]"
$nicknameInvalidPattern = '[\s\\%&\*\+/=\?\{\}\|<>\(\);:,\[\]"@]'
$nonRoutableSuffixPattern = '(?i)\.(local|lan|internal|intranet|corp|home|localdomain|private)$'

$findings = [System.Collections.Generic.List[pscustomobject]]::new()

function Add-Finding {
    param(
        [Parameter(Mandatory)] $Object,
        [Parameter(Mandatory)] [string] $Rule,
        [Parameter(Mandatory)] [ValidateSet('Error', 'Warning', 'Info')] [string] $Severity,
        [string] $Attribute,
        [string] $Value,
        [Parameter(Mandatory)] [string] $Recommendation
    )
    $findings.Add([pscustomobject]@{
            DistinguishedName = $Object.DistinguishedName
            ObjectClass       = $Object.ObjectClass
            SamAccountName    = $Object.SamAccountName
            Rule              = $Rule
            Severity          = $Severity
            Attribute         = $Attribute
            Value             = $Value
            Recommendation    = $Recommendation
        })
}

$adParams = @{}
if ($Server) { $adParams.Server = $Server }

$domain = Get-ADDomain @adParams
$forest = Get-ADForest @adParams
if (-not $SearchBase) { $SearchBase = $domain.DistinguishedName }

$forestSuffixes = @($forest.RootDomain) + @($forest.UPNSuffixes)
Write-Verbose "Forest UPN suffixes: $($forestSuffixes -join ', ')"

$userProperties = @(
    'UserPrincipalName', 'mail', 'proxyAddresses', 'mailNickname', 'displayName', 'givenName', 'sn',
    'lastLogonTimestamp', 'pwdLastSet', 'adminCount', 'Enabled', 'objectGUID', 'servicePrincipalName'
)
$userFilter = if ($IncludeDisabled) { '*' } else { 'Enabled -eq $true' }

Write-Verbose "Reading users under $SearchBase"
$users = @(Get-ADUser @adParams -SearchBase $SearchBase -Filter $userFilter -Properties $userProperties)
Write-Verbose "Reading groups under $SearchBase"
$groups = @(Get-ADGroup @adParams -SearchBase $SearchBase -Filter * -Properties mail, proxyAddresses, displayName, adminCount)

$staleCutoff = (Get-Date).AddDays(-$StaleDays)

foreach ($user in $users) {
    $upn = $user.UserPrincipalName

    if ([string]::IsNullOrWhiteSpace($upn)) {
        Add-Finding -Object $user -Rule 'UpnMissing' -Severity Error -Attribute 'userPrincipalName' `
            -Recommendation 'Set a UPN on a routable, verified suffix; otherwise the object syncs with an onmicrosoft.com UPN.'
    }
    else {
        $parts = $upn.Split('@')
        $suffix = if ($parts.Count -eq 2) { $parts[1] } else { '' }

        if ($parts.Count -ne 2 -or $parts[0].StartsWith('.') -or $parts[0].EndsWith('.') -or $parts[0].Contains('..')) {
            Add-Finding -Object $user -Rule 'UpnFormat' -Severity Error -Attribute 'userPrincipalName' -Value $upn `
                -Recommendation 'UPN must be a single local part and suffix with no leading, trailing or repeated dots.'
        }
        if ($parts[0] -match $upnInvalidPattern) {
            Add-Finding -Object $user -Rule 'UpnInvalidCharacter' -Severity Error -Attribute 'userPrincipalName' -Value $upn `
                -Recommendation 'Remove characters Entra ID rejects in the UPN prefix.'
        }
        if ($upn.Length -gt 113 -or $parts[0].Length -gt 64) {
            Add-Finding -Object $user -Rule 'UpnLength' -Severity Error -Attribute 'userPrincipalName' -Value $upn `
                -Recommendation 'UPN must be at most 113 characters with a local part of at most 64.'
        }
        if ($suffix -match $nonRoutableSuffixPattern -or $suffix -notmatch '\.') {
            Add-Finding -Object $user -Rule 'UpnSuffixNotRoutable' -Severity Error -Attribute 'userPrincipalName' -Value $upn `
                -Recommendation 'Add a routable UPN suffix to the forest, verify it in Entra and update the user.'
        }
        elseif ($VerifiedDomain.Count -gt 0 -and $suffix -notin $VerifiedDomain) {
            Add-Finding -Object $user -Rule 'UpnSuffixNotVerified' -Severity Error -Attribute 'userPrincipalName' -Value $upn `
                -Recommendation "Verify $suffix in Entra ID or move the user to a verified suffix."
        }
    }

    if ($user.mailNickname -and $user.mailNickname -match $nicknameInvalidPattern) {
        Add-Finding -Object $user -Rule 'MailNicknameInvalidCharacter' -Severity Error -Attribute 'mailNickname' -Value $user.mailNickname `
            -Recommendation 'Remove whitespace and reserved characters from mailNickname.'
    }
    if ($user.mailNickname -and $user.mailNickname.Length -gt 64) {
        Add-Finding -Object $user -Rule 'MailNicknameLength' -Severity Error -Attribute 'mailNickname' -Value $user.mailNickname `
            -Recommendation 'mailNickname must be at most 64 characters.'
    }
    if ($user.displayName -and $user.displayName.Length -gt 256) {
        Add-Finding -Object $user -Rule 'DisplayNameLength' -Severity Error -Attribute 'displayName' `
            -Recommendation 'displayName must be at most 256 characters.'
    }
    if ([string]::IsNullOrWhiteSpace($user.displayName)) {
        Add-Finding -Object $user -Rule 'DisplayNameMissing' -Severity Warning -Attribute 'displayName' `
            -Recommendation 'Set displayName so the account is identifiable in Entra and the global address list.'
    }

    foreach ($address in @($user.proxyAddresses)) {
        if ($address -match '\s' -or $address -notmatch '^[A-Za-z0-9]+:') {
            Add-Finding -Object $user -Rule 'ProxyAddressFormat' -Severity Error -Attribute 'proxyAddresses' -Value $address `
                -Recommendation 'proxyAddresses entries need a type prefix (SMTP:/smtp:) and no whitespace.'
        }
    }

    if ($user.Enabled) {
        $lastLogon = if ($user.lastLogonTimestamp) { [datetime]::FromFileTimeUtc($user.lastLogonTimestamp) } else { $null }
        $pwdSet = if ($user.pwdLastSet) { [datetime]::FromFileTimeUtc($user.pwdLastSet) } else { $null }
        if ((-not $lastLogon -or $lastLogon -lt $staleCutoff) -and (-not $pwdSet -or $pwdSet -lt $staleCutoff)) {
            Add-Finding -Object $user -Rule 'StaleAccount' -Severity Warning -Attribute 'lastLogonTimestamp' `
                -Value $(if ($lastLogon) { $lastLogon.ToString('o') } else { 'never' }) `
                -Recommendation 'Disable or remove before sync, or exclude from the sync scope.'
        }
    }

    if ($user.adminCount -eq 1) {
        Add-Finding -Object $user -Rule 'PrivilegedAccount' -Severity Warning -Attribute 'adminCount' -Value '1' `
            -Recommendation 'Exclude from sync scope. Use separate cloud-only accounts for Entra and Microsoft 365 administration.'
    }

    if (@($user.servicePrincipalName).Count -gt 0) {
        Add-Finding -Object $user -Rule 'ServiceAccount' -Severity Info -Attribute 'servicePrincipalName' `
            -Recommendation 'Service accounts with SPNs usually do not need a cloud identity; exclude unless required.'
    }
}

function Find-Duplicate {
    param(
        [Parameter(Mandatory)] [object[]] $Objects,
        [Parameter(Mandatory)] [string] $Attribute,
        [Parameter(Mandatory)] [scriptblock] $Selector
    )
    $index = @{}
    foreach ($object in $Objects) {
        foreach ($value in @(& $Selector $object)) {
            if ([string]::IsNullOrWhiteSpace($value)) { continue }
            $key = $value.ToLowerInvariant()
            if (-not $index.ContainsKey($key)) { $index[$key] = [System.Collections.Generic.List[object]]::new() }
            $index[$key].Add($object)
        }
    }
    foreach ($entry in $index.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }) {
        foreach ($object in $entry.Value) {
            Add-Finding -Object $object -Rule "Duplicate$Attribute" -Severity Error -Attribute $Attribute -Value $entry.Key `
                -Recommendation "Value is shared by $($entry.Value.Count) objects; sync will quarantine all but one."
        }
    }
}

$allObjects = @($users) + @($groups)
Find-Duplicate -Objects $users -Attribute 'UserPrincipalName' -Selector { param($o) $o.UserPrincipalName }
Find-Duplicate -Objects $allObjects -Attribute 'Mail' -Selector { param($o) $o.mail }
Find-Duplicate -Objects $allObjects -Attribute 'ProxyAddress' -Selector {
    param($o) @($o.proxyAddresses) | ForEach-Object { ($_ -replace '^(?i)smtp:', '') }
}

foreach ($group in $groups | Where-Object { $_.adminCount -eq 1 }) {
    Add-Finding -Object $group -Rule 'PrivilegedGroup' -Severity Info -Attribute 'adminCount' -Value '1' `
        -Recommendation 'Protected group; do not sync or convert its source of authority.'
}

$summary = [ordered]@{
    reportTimeUtc    = (Get-Date).ToUniversalTime().ToString('o')
    domain           = $domain.DNSRoot
    searchBase       = $SearchBase
    forestUpnSuffix  = $forestSuffixes
    usersAssessed    = $users.Count
    groupsAssessed   = $groups.Count
    errors           = @($findings | Where-Object Severity -EQ 'Error').Count
    warnings         = @($findings | Where-Object Severity -EQ 'Warning').Count
    byRule           = [ordered]@{}
    readyForSync     = -not ($findings | Where-Object Severity -EQ 'Error')
}
$findings | Group-Object Rule | Sort-Object Count -Descending | ForEach-Object { $summary.byRule[$_.Name] = $_.Count }

if ($PSCmdlet.ShouldProcess($OutputPath, 'Write readiness report')) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    $findings | Export-Csv -Path (Join-Path $OutputPath 'findings.csv') -NoTypeInformation -Encoding utf8
    $summary | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $OutputPath 'summary.json') -Encoding utf8
    Write-Information "Report written to $OutputPath" -InformationAction Continue
}

[pscustomobject]$summary
