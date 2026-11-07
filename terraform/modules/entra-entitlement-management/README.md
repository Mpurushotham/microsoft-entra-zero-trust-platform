# entra-entitlement-management

Microsoft Entra ID Governance **entitlement management**: catalogs, access packages that
grant group membership, and one assignment policy per package with approval, expiry and
recurring access reviews. Follows Microsoft's
[entitlement management deployment guidance](https://learn.microsoft.com/entra/id-governance/entitlement-management-overview).

## Design

- Access is time-bound by default (`duration_in_days = 180`) and reviewed quarterly by the
  requestor's manager; denied or unreviewed access is removed.
- Approval defaults to the requestor's manager. Set `approver_type = "groupMembers"` with
  `approver_group_ids` for privileged packages (for example Tier-0 admin access approved by
  the PIM approvers group). Backup approvers are added as `backup = true`.
- Groups granted by a package are associated with its catalog automatically; extra catalog
  resources can be listed in `resource_group_ids`.
- Role-assignable groups can be catalog resources; dynamic groups cannot.

## Licensing and permissions

Requires Microsoft Entra ID Governance (or Entra ID P2 for the base features). The
deployment identity needs `EntitlementManagement.ReadWrite.All`.

## Inputs

| Name | Type | Default |
|---|---|---|
| `name_prefix`, `environment` | string | required |
| `catalogs` | map(object({ description, externally_visible?, resource_group_ids? })) | required |
| `access_packages` | map(object({ catalog_key, description, hidden?, group_ids, access_type?, policy })) | required |

## Outputs

| Name | Description |
|---|---|
| `catalog_ids` | `{ key => id }` |
| `access_packages` | `{ key => { id, display_name } }` |

## Example

```hcl
module "entitlement_management" {
  source      = "../../modules/entra-entitlement-management"
  name_prefix = "zt"
  environment = "dev"
  catalogs = {
    "workforce" = { description = "Workforce access" }
  }
  access_packages = {
    "developers" = {
      catalog_key = "workforce"
      description = "Developer tooling and non-production subscriptions."
      group_ids   = [data.azuread_group.developers.object_id]
      policy      = {}
    }
  }
}
```
