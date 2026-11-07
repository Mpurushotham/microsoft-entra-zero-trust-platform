# entra-administrative-units

Administrative units (AUs) for delegated, least-privilege administration, plus directory
roles scoped to them. Follows Microsoft's
[administrative units guidance](https://learn.microsoft.com/entra/identity/role-based-access-control/administrative-units):
helpdesk and regional admins get roles at AU scope instead of tenant scope.

## Notes

- Static membership only. Seed members (users, groups, devices) through
  `member_object_ids`; later changes made in the portal or by automation are not reverted
  (`members` is ignored).
- Dynamic membership and *restricted management* AUs are not exposed by `azuread` 3.x.
  Restricted management can only be set at creation, so create those AUs with
  `msgraph_resource` (`directory/administrativeUnits`, `isMemberManagementRestricted = true`)
  if Tier-0 objects must be protected from tenant-scoped User/Groups Administrators.
- Only roles that support AU scope (User, Groups, Helpdesk, Password, Authentication,
  License, Cloud Device, Printer, Teams, SharePoint and Exchange Recipient
  administrators, among others) can be assigned in `scoped_role_assignments`.

## Inputs

| Name | Type | Default |
|---|---|---|
| `name_prefix` | string | required |
| `environment` | string (`dev`/`prod`) | required |
| `administrative_units` | map(object({ description, hidden_membership_enabled?, member_object_ids? })) | required |
| `scoped_role_assignments` | map(object({ administrative_unit_key, role_template_id, principal_object_id })) | `{}` |

## Outputs

| Name | Description |
|---|---|
| `administrative_units` | `{ key => { object_id, display_name } }` |

## Example

```hcl
module "administrative_units" {
  source      = "../../modules/entra-administrative-units"
  name_prefix = "zt"
  environment = "dev"
  administrative_units = {
    "users-standard" = { description = "Standard workforce users managed by the service desk." }
  }
  scoped_role_assignments = {
    helpdesk = {
      administrative_unit_key = "users-standard"
      role_template_id        = "729827e3-9c14-49f7-bb1b-9608f156bbb8" # Helpdesk Administrator
      principal_object_id     = module.groups.object_ids["pim-helpdesk-administrators"]
    }
  }
}
```
