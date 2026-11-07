# entra-groups

Data-driven Microsoft Entra security groups: assigned, dynamic and role-assignable.
Display names follow `<prefix>-<env>-<key>` so other stacks can resolve them with
`data "azuread_group"` instead of remote state.

## Behaviour

- `dynamic_rule` set: dynamic membership group (`DynamicMembership`). Requires Entra ID P1.
- `assignable_to_role = true`: can hold directory role assignments and is eligible for
  PIM for Groups. Only Privileged Role Administrators can change membership. Cannot be dynamic.
- `members` is ignored after creation: membership is governed by PIM, entitlement
  management, lifecycle workflows or the dynamic rule, never by this module.

## Inputs

| Name | Type | Default |
|---|---|---|
| `name_prefix` | string | required |
| `environment` | string (`dev`/`prod`) | required |
| `groups` | map(object({ description, dynamic_rule?, assignable_to_role?, owner_object_ids? })) | required |
| `default_owner_object_ids` | list(string) | `[]` |

## Outputs

| Name | Description |
|---|---|
| `groups` | `{ key => { object_id, display_name } }` |
| `object_ids` | `{ key => object_id }` |

## Example

```hcl
module "groups" {
  source      = "../../modules/entra-groups"
  name_prefix = "zt"
  environment = "dev"
  groups = {
    "persona-internals" = {
      description  = "All enabled member users."
      dynamic_rule = "(user.userType -eq \"Member\") and (user.accountEnabled -eq true)"
    }
    "pim-security-administrators" = {
      description        = "JIT members receive Security Administrator."
      assignable_to_role = true
    }
  }
}
```
