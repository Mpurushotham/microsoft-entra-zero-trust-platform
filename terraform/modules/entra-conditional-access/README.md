# entra-conditional-access

Data-driven Microsoft Entra Conditional Access. Every policy is an entry in `policies`
(`azuread_conditional_access_policy`) or `token_protection_policies` (Microsoft Graph
beta). The module enforces two guardrails for every policy:

1. **Emergency access exclusion**: `emergency_access_group_ids` is appended to
   `excluded_groups` of every policy, and the variable cannot be empty.
2. **Safe default state**: policies without an explicit `state` use `default_state`,
   which defaults to `enabledForReportingButNotEnforced` (report-only).

The policy catalogue itself lives in stack `20-entra-conditional-access`, modelled on
Microsoft's [Conditional Access templates](https://learn.microsoft.com/entra/identity/conditional-access/concept-conditional-access-policy-common)
and the [Zero Trust persona-based framework](https://learn.microsoft.com/azure/architecture/guide/security/conditional-access-framework).

## Rolling out

1. Apply with `default_state = "enabledForReportingButNotEnforced"`.
2. Review the *Conditional Access insights and reporting* workbook and sign-in logs
   (Report-only result) for at least 7 days; use the What If tool for edge cases.
3. Promote individual policies by setting `state = "enabled"` on that entry, not by flipping
   `default_state` for everything at once.

## Token protection

`secureSignInSession` exists only in Graph **beta**, so token protection policies are created
with `msgraph_resource` (`api_version = "beta"`). Supported today for Windows desktop
clients against Exchange Online, SharePoint Online and Teams; target pilot groups or admin
roles first.

## Inputs

| Name | Type | Default |
|---|---|---|
| `default_state` | string | `"enabledForReportingButNotEnforced"` |
| `emergency_access_group_ids` | list(string), non-empty | required |
| `policies` | map(object), see `variables.tf` | required |
| `token_protection_policies` | map(object) | `{}` |

Role-based targeting uses directory **role template IDs** (for example Global Administrator
`62e90394-69f5-4237-9190-012177145e10`). Location IDs are named-location object IDs, or
`All` / `AllTrusted`.

## Outputs

| Name | Description |
|---|---|
| `policies` | `{ key => { object_id, display_name, state } }` |

## Example

```hcl
module "conditional_access" {
  source                     = "../../modules/entra-conditional-access"
  emergency_access_group_ids = [data.azuread_group.emergency_access.object_id]
  policies = {
    CA000 = {
      display_name          = "CA000-Global-BaseProtection-AllApps-AnyPlatform-Block-LegacyAuthentication"
      client_app_types      = ["exchangeActiveSync", "other"]
      included_users        = ["All"]
      included_applications = ["All"]
      grant                 = { built_in_controls = ["block"] }
    }
  }
}
```
