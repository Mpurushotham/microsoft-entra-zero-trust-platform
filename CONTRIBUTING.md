# Contributing

Thank you for improving the platform. Changes here can alter how every user in a tenant signs in, so the process favours small, reviewed and reversible changes.

## Before you start

* Open an issue describing the change and the Microsoft Learn guidance it follows.
* Significant design changes need an architecture decision record in `docs/architecture/adr/`.
* Never use a production tenant for development. Use a test tenant and the `dev` environment.

## Local setup

| Tool | Version |
|---|---|
| Terraform | 1.9 or later |
| tflint | Current, uses `.tflint.hcl` |
| checkov | Current |
| pre-commit | Current |
| PowerShell | 7.4 or later, with PSScriptAnalyzer |

```bash
pip install pre-commit checkov
pre-commit install
pre-commit run --all-files
```

The hooks in `.pre-commit-config.yaml` run `terraform fmt`, `terraform validate`, tflint, checkov, whitespace and YAML checks, private key detection and gitleaks.

Validate a stack offline without touching a tenant:

```bash
cd terraform/stacks/<NN-topic>
terraform init -backend=false
terraform validate
```

## Conventions

### Terraform

* Terraform `>= 1.9`; providers pinned with `~>` in each `versions.tf`: `hashicorp/azuread`, `hashicorp/azurerm`, `microsoft/msgraph`, and `Azure/azapi` only where needed.
* Prefer typed `azuread` resources; use `msgraph_resource` for anything `azuread` lacks. Use Graph `beta` only when `v1.0` has no equivalent, and say why beside the resource.
* Modules live in `terraform/modules/<kebab-name>/` with `versions.tf` (no provider blocks), `variables.tf`, `outputs.tf`, one file per concern, and a `README.md`.
* Stacks live in `terraform/stacks/<NN-topic>/` with a partial `backend "azurerm" {}`, `env/dev.tfvars`, `env/prod.tfvars` and a `README.md`.
* Every variable has a type, and a validation block with a clear `error_message` where meaningful. Identifiers are `snake_case`; directories are `kebab-case`.
* Display names follow `${name_prefix}-${environment}-<purpose>`.
* Conditional Access policies default to `enabledForReportingButNotEnforced` and always exclude the break-glass group.
* Comment only the non-obvious *why*.

### PowerShell

* PowerShell 7, approved verbs, `[CmdletBinding()]`, comment-based help with the Graph scopes the script needs.
* Scripts that change state support a preview mode (`-WhatIf` or a preview-by-default `-Execute` switch).
* Clean PSScriptAnalyzer results.

### Documentation

* Follow [docs/contributing.md](docs/contributing.md): every page in `docs/SUMMARY.md`, a References section citing Microsoft Learn, Mermaid diagrams, relative links.

### Commits and pull requests

* Conventional commit style: `feat(20-entra-conditional-access): add token protection policy`.
* One stack per pull request where possible. The workflow posts the plan; reviewers read the plan, not only the diff.
* Pull requests that touch `20-entra-conditional-access` include the report-only evidence if they change a policy state.

## Review and merge

1. `ci-quality.yml` and the stack workflow's plan must pass.
2. A code owner approves.
3. Merge to `main` applies to `dev`; `prod` waits for an environment reviewer.

## Secrets

Never commit secrets, tenant IDs, real domains, user names, hardware hashes, plan files or state files. See [SECURITY.md](SECURITY.md).
