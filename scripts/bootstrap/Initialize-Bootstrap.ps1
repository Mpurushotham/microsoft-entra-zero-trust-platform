#Requires -Version 7.2
<#
.SYNOPSIS
    One-time bootstrap of Terraform state storage and the GitHub OIDC identities.

.DESCRIPTION
    Runs terraform/stacks/00-bootstrap with a temporary local backend, migrates the resulting
    state into the storage account it just created, and optionally configures the GitHub
    repository secrets, variables and environments the workflows expect.

    Run as a human operator signed in with Azure CLI who holds:
      - Owner (or Contributor + Role Based Access Control Administrator) on the subscription
      - Privileged Role Administrator and Cloud Application Administrator in Entra ID
        (or Global Administrator) to create app registrations and grant admin consent

.PARAMETER VarFile
    tfvars file relative to the 00-bootstrap stack.

.PARAMETER ConfigureGitHub
    Use the GitHub CLI to create the dev/prod environments and set secrets and variables.

.PARAMETER SkipMigration
    Leave state local (for a throwaway lab). Not suitable for CI.

.EXAMPLE
    ./scripts/bootstrap/Initialize-Bootstrap.ps1 -WhatIf

.EXAMPLE
    ./scripts/bootstrap/Initialize-Bootstrap.ps1 -ConfigureGitHub -ProdReviewer Mpurushotham

.NOTES
    Author: Purushotham Muktha
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [ValidateNotNullOrEmpty()]
    [string] $VarFile = 'env/global.tfvars',

    [ValidatePattern('^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$')]
    [string] $Repository = 'Mpurushotham/microsoft-entra-zero-trust-platform',

    [switch] $ConfigureGitHub,

    [string[]] $ProdReviewer = @(),

    [switch] $SkipMigration,

    [ValidateRange(1, 30)]
    [int] $RbacWaitMinutes = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$stackPath = Join-Path $PSScriptRoot '../../terraform/stacks/00-bootstrap' | Resolve-Path
$overridePath = Join-Path $stackPath 'backend_override.tf'
$stateKey = '00-bootstrap/global.tfstate'

function Assert-Command {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string] $Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found on PATH."
    }
}

function Invoke-Terraform {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]] $Arguments)
    & terraform "-chdir=$stackPath" @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "terraform $($Arguments[0]) failed with exit code $LASTEXITCODE."
    }
}

function Wait-StateAccess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string] $StorageAccount,
        [Parameter(Mandatory)][string] $Container,
        [Parameter(Mandatory)][int] $Minutes
    )
    # Data-plane role assignments can take several minutes to propagate.
    $deadline = (Get-Date).AddMinutes($Minutes)
    while ((Get-Date) -lt $deadline) {
        & az storage blob list --account-name $StorageAccount --container-name $Container `
            --auth-mode login --num-results 1 --only-show-errors --output none 2>$null
        if ($LASTEXITCODE -eq 0) { return }
        Write-Verbose 'Waiting for Storage Blob Data Contributor to propagate...'
        Start-Sleep -Seconds 20
    }
    throw "No data-plane access to $StorageAccount/$Container after $Minutes minutes."
}

function Set-GitHubConfiguration {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][pscustomobject] $Outputs,
        [Parameter(Mandatory)][string] $Repo,
        [string[]] $Reviewers
    )
    Assert-Command -Name 'gh'

    $repoSecrets = [ordered]@{
        AZURE_TENANT_ID       = $Outputs.tenant_id.value
        AZURE_SUBSCRIPTION_ID = $Outputs.subscription_id.value
    }
    foreach ($ghEnv in $Outputs.github_plan_client_ids.value.PSObject.Properties) {
        $repoSecrets["AZURE_PLAN_CLIENT_ID_$($ghEnv.Name.ToUpperInvariant())"] = $ghEnv.Value
    }
    $repoVariables = [ordered]@{
        TFSTATE_RG = $Outputs.tfstate_resource_group.value
        TFSTATE_SA = $Outputs.tfstate_storage_account.value
    }

    foreach ($name in $repoSecrets.Keys) {
        if ($PSCmdlet.ShouldProcess("$Repo secret $name", 'gh secret set')) {
            $repoSecrets[$name] | & gh secret set $name --repo $Repo
        }
    }
    foreach ($name in $repoVariables.Keys) {
        if ($PSCmdlet.ShouldProcess("$Repo variable $name", 'gh variable set')) {
            & gh variable set $name --repo $Repo --body $repoVariables[$name]
        }
    }

    foreach ($ghEnv in $Outputs.github_apply_client_ids.value.PSObject.Properties) {
        if ($PSCmdlet.ShouldProcess("$Repo environment $($ghEnv.Name)", 'create or update')) {
            $body = @{ deployment_branch_policy = @{ protected_branches = $true; custom_branch_policies = $false } }
            if ($ghEnv.Name -eq 'prod' -and $Reviewers.Count -gt 0) {
                $ids = foreach ($login in $Reviewers) { [int](& gh api "users/$login" --jq '.id') }
                $body.reviewers = @($ids | ForEach-Object { @{ type = 'User'; id = $_ } })
                $body.prevent_self_review = $false
            }
            $body | ConvertTo-Json -Depth 5 | & gh api --method PUT "repos/$Repo/environments/$($ghEnv.Name)" --input - | Out-Null
            $ghEnv.Value | & gh secret set AZURE_CLIENT_ID --repo $Repo --env $ghEnv.Name
        }
    }
}

Assert-Command -Name 'terraform'
Assert-Command -Name 'az'

$account = & az account show --output json | ConvertFrom-Json
if (-not $account) { throw 'Run az login first.' }
Write-Information "Tenant $($account.tenantId), subscription $($account.name) ($($account.id))" -InformationAction Continue
$env:ARM_SUBSCRIPTION_ID = $account.id
$env:ARM_TENANT_ID = $account.tenantId

$varFilePath = Join-Path $stackPath $VarFile
if (-not (Test-Path $varFilePath)) { throw "Variable file not found: $varFilePath" }
if ((Get-Content $varFilePath -Raw) -match '00000000-0000-0000-0000-000000000000') {
    $me = & az ad signed-in-user show --query id --output tsv
    throw "operator_object_ids in $VarFile still holds the placeholder. Your object ID is $me."
}

Set-Content -Path $overridePath -Value "terraform {`n  backend `"local`" {}`n}`n" -Encoding utf8NoBOM
try {
    Invoke-Terraform -Arguments @('init', '-reconfigure', '-input=false')
    Invoke-Terraform -Arguments @('plan', '-input=false', "-var-file=$VarFile", '-out=bootstrap.tfplan')

    if (-not $PSCmdlet.ShouldProcess($stackPath, 'terraform apply bootstrap.tfplan')) {
        Write-Information 'Plan created; apply skipped.' -InformationAction Continue
        return
    }
    Invoke-Terraform -Arguments @('apply', '-input=false', 'bootstrap.tfplan')
    $outputs = & terraform "-chdir=$stackPath" output -json | ConvertFrom-Json
}
finally {
    Remove-Item -Path $overridePath -ErrorAction SilentlyContinue
    Remove-Item -Path (Join-Path $stackPath 'bootstrap.tfplan') -ErrorAction SilentlyContinue
}

if (-not $SkipMigration) {
    $sa = $outputs.tfstate_storage_account.value
    $container = $outputs.tfstate_container.value
    Wait-StateAccess -StorageAccount $sa -Container $container -Minutes $RbacWaitMinutes

    Invoke-Terraform -Arguments @(
        'init', '-migrate-state', '-force-copy', '-input=false',
        "-backend-config=resource_group_name=$($outputs.tfstate_resource_group.value)",
        "-backend-config=storage_account_name=$sa",
        "-backend-config=container_name=$container",
        "-backend-config=key=$stateKey",
        '-backend-config=use_azuread_auth=true'
    )

    # Local copies can hold sensitive attributes once the remote copy is confirmed.
    foreach ($file in 'terraform.tfstate', 'terraform.tfstate.backup') {
        $path = Join-Path $stackPath $file
        if ((Test-Path $path) -and $PSCmdlet.ShouldProcess($path, 'Remove local state copy')) {
            Remove-Item -Path $path
        }
    }
}

if ($ConfigureGitHub) {
    Set-GitHubConfiguration -Outputs $outputs -Repo $Repository -Reviewers $ProdReviewer
}

[pscustomobject]@{
    TFSTATE_RG                = $outputs.tfstate_resource_group.value
    TFSTATE_SA                = $outputs.tfstate_storage_account.value
    AZURE_TENANT_ID           = $outputs.tenant_id.value
    AZURE_SUBSCRIPTION_ID     = $outputs.subscription_id.value
    AZURE_PLAN_CLIENT_ID_DEV  = $outputs.github_plan_client_ids.value.dev
    AZURE_PLAN_CLIENT_ID_PROD = $outputs.github_plan_client_ids.value.prod
    AZURE_CLIENT_ID_DEV_ENV   = $outputs.github_apply_client_ids.value.dev
    AZURE_CLIENT_ID_PROD_ENV  = $outputs.github_apply_client_ids.value.prod
}
