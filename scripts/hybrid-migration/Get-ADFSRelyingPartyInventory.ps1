#Requires -Version 5.1

<#
.SYNOPSIS
    Exports AD FS relying party trusts and OIDC application groups with their claim rules, and
    classifies each for migration to Microsoft Entra enterprise applications.

.DESCRIPTION
    Reads every relying party trust and application group from the AD FS farm and produces:

      - inventory.csv            one row per relying party / application with a readiness verdict
      - inventory.json           the same with full claim rules
      - claim-rules/<name>.txt   issuance, authorization and additional authentication rules
      - migrated_applications.auto.tfvars.json
                                 a starting point for terraform/stacks/40-hybrid-migration for every
                                 relying party rated Ready (review before committing)

    Readiness follows the checks Microsoft applies in the Entra "AD FS application migration"
    report: complex claim rules, custom attribute stores, additional authentication rules,
    WS-Federation, token encryption, and SHA-1 signing.

.PARAMETER OutputPath
    Folder for the inventory. Created when missing.

.PARAMETER IncludeDisabled
    Include disabled relying party trusts.

.PARAMETER NamePrefixToStrip
    Prefix removed from relying party names when building Terraform keys.

.EXAMPLE
    ./Get-ADFSRelyingPartyInventory.ps1 -OutputPath C:\Migration\adfs-inventory

.NOTES
    Author: Purushotham Muktha
    Run on the primary AD FS server as a farm administrator. The AD FS module ships with Windows
    Server and loads under Windows PowerShell 5.1 or PowerShell 7 with Windows compatibility.
    Reference: https://learn.microsoft.com/entra/identity/enterprise-apps/migrate-adfs-apps-stages
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string] $OutputPath = (Join-Path -Path (Get-Location) -ChildPath "adfs-inventory-$(Get-Date -Format yyyyMMdd-HHmmss)"),

    [switch] $IncludeDisabled,

    [string] $NamePrefixToStrip = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Get-Module -ListAvailable -Name ADFS)) {
    throw 'The ADFS module is not available. Run this script on an AD FS server.'
}
Import-Module ADFS

# Claim rule fragments Entra claims mapping cannot reproduce one-to-one.
$complexRulePatterns = [ordered]@{
    CustomAttributeStore = 'store\s*=\s*"(?!Active Directory)[^"]+"'
    SqlOrLdapQuery       = 'query\s*=\s*"'
    RegexReplace         = 'RegExReplace\s*\('
    AddToPipeline        = '=>\s*add\s*\('
    ConditionalOnClaims  = '&&\s*c\d*:\['
    NotExists            = 'NOT\s+EXISTS\s*\('
}

function ConvertTo-Slug {
    param([Parameter(Mandatory)] [string] $Name)
    $slug = $Name
    if ($NamePrefixToStrip -and $slug.StartsWith($NamePrefixToStrip)) { $slug = $slug.Substring($NamePrefixToStrip.Length) }
    $slug = ($slug.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    if ($slug.Length -gt 40) { $slug = $slug.Substring(0, 40).Trim('-') }
    return $slug
}

function Get-RuleFinding {
    param([string] $Rules)
    $found = @()
    if ([string]::IsNullOrWhiteSpace($Rules)) { return $found }
    foreach ($entry in $complexRulePatterns.GetEnumerator()) {
        if ($Rules -match $entry.Value) { $found += $entry.Key }
    }
    return $found
}

$inventory = [System.Collections.Generic.List[pscustomobject]]::new()

$trusts = @(Get-AdfsRelyingPartyTrust)
if (-not $IncludeDisabled) { $trusts = @($trusts | Where-Object Enabled) }

foreach ($rp in $trusts) {
    $issuance = [string]$rp.IssuanceTransformRules
    $authorization = [string]$rp.IssuanceAuthorizationRules
    $additionalAuth = [string]$rp.AdditionalAuthenticationRules

    $samlEndpoints = @($rp.SamlEndpoints)
    $protocol = if ($samlEndpoints.Count -gt 0) { 'saml' } elseif ($rp.WSFedEndpoint) { 'wsfed' } else { 'unknown' }

    $issues = [System.Collections.Generic.List[string]]::new()
    foreach ($f in (Get-RuleFinding -Rules $issuance)) { $issues.Add("IssuanceRule:$f") }
    foreach ($f in (Get-RuleFinding -Rules $authorization)) { $issues.Add("AuthorizationRule:$f") }
    if ($additionalAuth) { $issues.Add('AdditionalAuthenticationRules:MapToConditionalAccess') }
    if ($rp.AccessControlPolicyName -and $rp.AccessControlPolicyName -notin @('Permit everyone', 'Permit everyone and require MFA')) {
        $issues.Add("AccessControlPolicy:$($rp.AccessControlPolicyName)")
    }
    if ($protocol -eq 'wsfed') { $issues.Add('Protocol:WsFederation') }
    if ($protocol -eq 'unknown') { $issues.Add('Protocol:NoEndpoints') }
    if ($rp.EncryptionCertificate) { $issues.Add('TokenEncryption:ConfigureInEntra') }
    if ($rp.SignatureAlgorithm -match 'sha1') { $issues.Add('SigningAlgorithm:SHA1') }
    if (@($rp.Identifier).Count -gt 1) { $issues.Add('MultipleIdentifiers') }

    $blocking = @($issues | Where-Object { $_ -match 'CustomAttributeStore|SqlOrLdapQuery|NoEndpoints' })
    $verdict = if ($blocking.Count -gt 0) { 'Blocked' } elseif ($issues.Count -gt 0) { 'NeedsReview' } else { 'Ready' }

    $acs = @($samlEndpoints | Where-Object { $_.Protocol -eq 'SAMLAssertionConsumer' } | ForEach-Object { [string]$_.Location })
    $logout = @($samlEndpoints | Where-Object { $_.Protocol -eq 'SAMLLogout' } | ForEach-Object { [string]$_.Location }) | Select-Object -First 1

    $inventory.Add([pscustomobject]@{
            Key                     = ConvertTo-Slug -Name $rp.Name
            Name                    = $rp.Name
            Kind                    = 'RelyingPartyTrust'
            Enabled                 = $rp.Enabled
            Protocol                = $protocol
            Identifier              = @($rp.Identifier)
            ReplyUrls               = if ($protocol -eq 'wsfed') { @([string]$rp.WSFedEndpoint) } else { $acs }
            LogoutUrl               = $logout
            AccessControlPolicy     = $rp.AccessControlPolicyName
            SignatureAlgorithm      = $rp.SignatureAlgorithm
            TokenEncryption         = [bool]$rp.EncryptionCertificate
            MetadataUrl             = if ($rp.MetadataUrl) { [string]$rp.MetadataUrl } else { $null }
            Verdict                 = $verdict
            Issues                  = @($issues)
            IssuanceTransformRules  = $issuance
            AuthorizationRules      = $authorization
            AdditionalAuthRules     = $additionalAuth
        })
}

foreach ($appGroup in @(Get-AdfsApplicationGroup)) {
    foreach ($app in @($appGroup.Applications)) {
        # TypeNames survives the deserialization that happens when ADFS loads through Windows PowerShell compatibility.
        $kind = ($app.PSObject.TypeNames[0] -split '\.')[-1]
        $issues = [System.Collections.Generic.List[string]]::new()
        $issuance = ''
        $redirects = @()
        $identifier = @()

        switch -Wildcard ($kind) {
            '*ServerApplication*' { $redirects = @($app.RedirectUri); $identifier = @($app.Identifier) }
            '*NativeClient*' { $redirects = @($app.RedirectUri); $identifier = @($app.Identifier); $issues.Add('PublicClient:RegisterAsMobileDesktop') }
            '*WebApi*' {
                $identifier = @($app.Identifier)
                $issuance = [string]$app.IssuanceTransformRules
                foreach ($f in (Get-RuleFinding -Rules $issuance)) { $issues.Add("IssuanceRule:$f") }
                $issues.Add('WebApi:ExposeScopesInAppRegistration')
            }
        }

        $verdict = if (@($issues | Where-Object { $_ -match 'CustomAttributeStore|SqlOrLdapQuery' }).Count -gt 0) { 'Blocked' } elseif ($issues.Count -gt 0) { 'NeedsReview' } else { 'Ready' }

        $inventory.Add([pscustomobject]@{
                Key                    = ConvertTo-Slug -Name "$($appGroup.Name)-$($app.Name)"
                Name                   = "$($appGroup.Name) / $($app.Name)"
                Kind                   = $kind
                Enabled                = $appGroup.Enabled
                Protocol               = 'oidc'
                Identifier             = $identifier
                ReplyUrls              = @($redirects | Where-Object { $_ })
                LogoutUrl              = $null
                AccessControlPolicy    = $null
                SignatureAlgorithm     = $null
                TokenEncryption        = $false
                MetadataUrl            = $null
                Verdict                = $verdict
                Issues                 = @($issues)
                IssuanceTransformRules = $issuance
                AuthorizationRules     = ''
                AdditionalAuthRules    = ''
            })
    }
}

$tfvars = [ordered]@{ migrated_applications = [ordered]@{} }
foreach ($item in $inventory | Where-Object { $_.Verdict -eq 'Ready' -and $_.Protocol -in @('saml', 'oidc') -and $_.Kind -notmatch 'WebApi' }) {
    $entry = [ordered]@{
        display_name       = $item.Key
        protocol           = $item.Protocol
        adfs_relying_party = (@($item.Identifier) | Select-Object -First 1)
        redirect_uris      = @($item.ReplyUrls | Where-Object { $_ -like 'https://*' })
        assign_to_waves    = @('pilot')
    }
    if ($item.Protocol -eq 'saml') { $entry.identifier_uris = @($item.Identifier) }
    if ($item.LogoutUrl) { $entry.logout_url = $item.LogoutUrl }
    $tfvars.migrated_applications[$item.Key] = $entry
}

if ($PSCmdlet.ShouldProcess($OutputPath, 'Write AD FS inventory')) {
    $rulesPath = Join-Path $OutputPath 'claim-rules'
    New-Item -Path $rulesPath -ItemType Directory -Force | Out-Null

    foreach ($item in $inventory) {
        @(
            "# $($item.Name)"
            '## Issuance transform rules'
            $item.IssuanceTransformRules
            '## Issuance authorization rules'
            $item.AuthorizationRules
            '## Additional authentication rules'
            $item.AdditionalAuthRules
        ) | Set-Content -Path (Join-Path $rulesPath "$($item.Key).txt") -Encoding utf8
    }

    $inventory |
        Select-Object Key, Name, Kind, Enabled, Protocol,
        @{ n = 'Identifier'; e = { $_.Identifier -join ';' } },
        @{ n = 'ReplyUrls'; e = { $_.ReplyUrls -join ';' } },
        LogoutUrl, AccessControlPolicy, SignatureAlgorithm, TokenEncryption, Verdict,
        @{ n = 'Issues'; e = { $_.Issues -join ';' } } |
        Export-Csv -Path (Join-Path $OutputPath 'inventory.csv') -NoTypeInformation -Encoding utf8

    $inventory | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $OutputPath 'inventory.json') -Encoding utf8
    $tfvars | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $OutputPath 'migrated_applications.auto.tfvars.json') -Encoding utf8
    Write-Information "Inventory written to $OutputPath" -InformationAction Continue
}

$inventory | Group-Object Verdict | Select-Object @{ n = 'Verdict'; e = { $_.Name } }, Count
