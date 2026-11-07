# intune-rbac

Intune role-based access control: scope tags (`roleScopeTags`), automatic tagging of devices in groups (the `assign` action), and role assignments (`deviceAndAppManagementRoleAssignment`) of built-in or custom Intune roles to Entra groups.

The module looks up role definitions by display name from `deviceManagement/roleDefinitions`, so built-in roles such as `Help Desk Operator`, `Endpoint Security Manager`, `Policy and Profile manager` and `Read Only Operator` need no hard-coded GUIDs.

Intune roles are separate from Entra directory roles. Use Intune roles for day-to-day endpoint administration, and keep the Entra *Intune Administrator* role PIM-eligible only (stack 30).

**API version:** `beta`. `roleScopeTags`, and `roleScopeTagIds` on assignments, are beta-only.

## Inputs

`name_prefix`, `environment`, `scope_tags` (map of description + device_group_ids), `role_assignments` (map of role_display_name, member_group_ids, scope_type, scope_group_ids, scope_tag_keys).

## Outputs

`scope_tag_ids`, `role_assignment_ids`
