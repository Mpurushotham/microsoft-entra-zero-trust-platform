# 00-bootstrap

Creates what every other stack and workflow depends on:

- Resource group and hardened storage account for Terraform state (`tfstate` container)
- Per environment (`dev`, `prod`): a read-only **plan** identity and a write **apply** identity for GitHub
  Actions OIDC, with Microsoft Graph application permissions and Azure RBAC
- Per environment: the `<prefix>-<env>-secops-rg` resource group used by stack 70
- Resource provider registration for Log Analytics, Sentinel, Monitor and Entra diagnostics

One state file (`00-bootstrap/global.tfstate`) covers both environments; settings are in `env/global.tfvars`.

## First run (local, then migrate)

The stack cannot store state in a storage account that does not exist yet. An operator runs it once:

```powershell
az login --tenant <tenant-id>
az account set --subscription <subscription-id>
# Edit env/global.tfvars: operator_object_ids, state_storage_account_name, location
./scripts/bootstrap/Initialize-Bootstrap.ps1 -WhatIf          # plan only
./scripts/bootstrap/Initialize-Bootstrap.ps1 -ConfigureGitHub -ProdReviewer <github-login>
```

The script writes a gitignored `backend_override.tf` (local backend), applies, waits for the Storage Blob Data
Contributor assignment to propagate, then runs `terraform init -migrate-state` into the new account and deletes
the local state copies. With `-ConfigureGitHub` it sets the GitHub secrets, variables and environments.

Operator permissions: Owner on the subscription, plus Privileged Role Administrator and Cloud Application
Administrator (or Global Administrator) in Entra ID.

After the first run, the `00-bootstrap` workflow only plans (drift check). Changes to this stack are applied by an
operator with the same script, because the pipeline identities must not be able to grant themselves permissions.

## Identities

| Identity | Federated subjects | Graph permissions | Azure RBAC |
|---|---|---|---|
| `<prefix>-<env>-github-plan` | `pull_request`, `ref:refs/heads/main` | read-only set | Reader (subscription), Storage Blob Data Reader (state container) |
| `<prefix>-<env>-github-apply` | `environment:<env>` | write set | Storage Blob Data Contributor (state container), Log Analytics Contributor + Microsoft Sentinel Contributor (secops RG) |

The apply identity also gets the Entra **Security Administrator** role when stack 70 is enabled. Permission sets
per stack are in `locals.tf` (`stack_permissions`); drop a stack from `enabled_stacks` to withhold its permissions.

## Outputs

`tfstate_resource_group`, `tfstate_storage_account`, `tfstate_container`, `github_plan_client_ids`,
`github_apply_client_ids`, `tenant_id`, `subscription_id`, `secops_resource_groups`, `graph_permissions`.

After stack 70 is applied, set `state_log_analytics_workspace_id` to its workspace ID and re-run the script to send
state access logs to Sentinel.
