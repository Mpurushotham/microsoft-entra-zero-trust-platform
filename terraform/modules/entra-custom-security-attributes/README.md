# entra-custom-security-attributes

Custom security attribute sets and definitions (Microsoft Graph v1.0), used to classify
users, service principals and applications for ABAC, Conditional Access application
filters and lifecycle workflow scoping. See
[custom security attributes overview](https://learn.microsoft.com/entra/fundamentals/custom-security-attributes-overview).

## Behaviour to know

- Attribute sets and definitions **cannot be deleted** in Entra ID. Both resources carry
  `prevent_destroy`; retire a definition by changing its status to `Deprecated` in the portal.
- Only *Attribute Definition Administrator* (or an app with
  `CustomSecAttributeDefinition.ReadWrite.All`) can manage definitions. Global
  Administrators have no access by default.
- Values are assigned to objects separately (by HR provisioning or automation with
  `CustomSecAttributeAssignment.ReadWrite.All`).

## Inputs

| Name | Type | Default |
|---|---|---|
| `attribute_sets` | map(object({ description, max_attributes_per_set?, attributes? })) | `{}` |

## Outputs

| Name | Description |
|---|---|
| `definition_ids` | `{ "<set>_<attribute>" => id }` |
