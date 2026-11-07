# entra-pim

Microsoft Entra **Privileged Identity Management** for directory roles and
**PIM for Groups**, following Microsoft's
[PIM deployment plan](https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-deployment-plan).

## Building blocks

| Input | Resource | Use |
|---|---|---|
| `role_eligibilities` | `azuread_directory_role_eligibility_schedule_request` | Principal (user or role-assignable group) is *eligible* and activates the role in PIM |
| `role_assignments` | `azuread_directory_role_assignment` | Active role on a role-assignable group whose membership is itself just-in-time |
| `group_policies` | `azuread_group_role_management_policy` (`member`) | Activation duration, MFA, justification, ticket, approval and expiry for PIM for Groups |
| `group_eligible_members` | `azuread_privileged_access_group_eligibility_schedule` | Users eligible to activate group membership |
| `directory_role_policies` | `msgraph_update_resource` on `policies/roleManagementPolicies/{id}/rules/{ruleId}` | Activation and eligibility settings per directory role (azuread has no resource for this) |

Two patterns are supported and can be mixed:

- **Eligible role on group** (Tier 0): the group is PIM-eligible for the role, membership is
  granted through an approved access package and reviewed quarterly. Activation requires
  approval.
- **PIM for Groups** (Tier 1): the group holds the role actively; users are eligible
  *members* and activate membership for a few hours.

## Directory role rules managed

| Rule ID | Setting |
|---|---|
| `Expiration_EndUser_Assignment` | Maximum activation duration |
| `Enablement_EndUser_Assignment` | MFA / justification / ticket on activation |
| `Approval_EndUser_Assignment` | Approval and approver groups |
| `Expiration_Admin_Eligibility` | Maximum eligibility duration |

These rules are tenant singletons patched in place. Removing an entry stops managing the
rule but does not revert it.

## Notes

- Eligibility requests created by `azuread_directory_role_eligibility_schedule_request` are
  permanent eligibilities; recurring access reviews provide the expiry control.
- `require_multifactor_on_activation` conflicts with an authentication-context requirement.
  To require phishing-resistant MFA on activation, create a CA authentication context and
  switch the rule to `AuthenticationContext_EndUser_Assignment`.
- Permissions: `RoleManagement.ReadWrite.Directory`, `RoleManagementPolicy.ReadWrite.Directory`,
  `RoleManagementPolicy.ReadWrite.AzureADGroup`, `PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup`.

## Outputs

| Name | Description |
|---|---|
| `role_eligibility_ids`, `role_assignment_ids` | IDs per key |
| `group_policy_ids` | PIM for Groups policy ID per key |
| `directory_role_policy_ids` | Directory role policy ID per key |
