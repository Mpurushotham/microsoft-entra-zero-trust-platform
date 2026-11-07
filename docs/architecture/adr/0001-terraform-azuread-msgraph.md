# ADR-0001 Terraform with the azuread and msgraph providers

* Status: Accepted
* Date: 2026-11-01
* Deciders: Platform architecture

## Context

Entra ID and Intune configuration must be versioned, peer reviewed and reproducible across `dev` and `prod`. Options include portal configuration, PowerShell with the Microsoft Graph SDK, Microsoft365DSC, Bicep with the Microsoft Graph extension, and Terraform.

The `hashicorp/azuread` provider covers users, groups, applications, administrative units, named locations, Conditional Access, authentication strengths and several governance objects. It does not cover Intune, authentication methods policy details, lifecycle workflows or many beta resources. Microsoft's `microsoft/msgraph` provider exposes any Microsoft Graph resource through a generic `msgraph_resource` with a URL and body.

## Decision

* Use Terraform `>= 1.9` as the single codebase.
* Use `hashicorp/azuread` wherever it offers a typed resource.
* Use `microsoft/msgraph` (`msgraph_resource`) for Intune and any Graph resource that `azuread` lacks. Prefer Graph `v1.0`; use `beta` only where `v1.0` has no equivalent, and note the reason beside the resource.
* Use `hashicorp/azurerm` for Azure resources (state storage, Log Analytics, Sentinel).
* Use PowerShell only for operations with no declarative surface: AD DS assessment, domain conversion, Autopilot hash collection.

## Consequences

* One plan shows every change, across Azure, Entra and Intune.
* `msgraph_resource` bodies are JSON and less validated than typed resources; checkov and `terraform validate` catch less, so plan review matters more.
* Beta Graph endpoints can change; each beta usage is listed and reviewed at provider upgrades.

## Alternatives considered

| Option | Why not chosen |
|---|---|
| Portal configuration | Not reviewable, not reproducible |
| PowerShell only | Imperative, no plan, drift handling is manual |
| Microsoft365DSC | Strong for export and drift reporting, weaker for pull-request planning workflows |
| Bicep with Graph extension | Narrower coverage of Intune and governance at time of decision |

## References

* [Microsoft Graph overview of use](https://learn.microsoft.com/en-us/graph/use-the-api)
* [Terraform on Azure overview](https://learn.microsoft.com/en-us/azure/developer/terraform/overview)
* [Microsoft Graph permissions reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
