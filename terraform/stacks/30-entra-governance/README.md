# 30-entra-governance

Microsoft Entra ID Governance: Privileged Identity Management, entitlement management,
access reviews and lifecycle workflows. Follows Microsoft's
[PIM deployment plan](https://learn.microsoft.com/entra/id-governance/privileged-identity-management/pim-deployment-plan)
and [ID Governance deployment guidance](https://learn.microsoft.com/entra/id-governance/identity-governance-overview).

## Privileged access model

| Tier | Groups | Role binding | How a person gets access |
|---|---|---|---|
| 0 | `pim-global-administrators`, `pim-privileged-role-administrators`, `pim-privileged-authentication-administrators` | Group is PIM-**eligible** for the role | Request the hidden access package (dedicated admin accounts only), approved by `pim-approvers`, 90 days; then activate the role for 2 h with MFA, justification and approval |
| 1 | `pim-security-administrators`, `pim-conditional-access-administrators`, `pim-intune-administrators`, `pim-user-administrators`, `pim-global-readers`, `pim-security-readers` | Group holds the role **actively** | Eligible member (PIM for Groups) activates membership for 4 h with MFA and justification |
| 2 | `pim-helpdesk-administrators` | Helpdesk Administrator scoped to the `users-standard` AU (stack 10) | Same as Tier 1 |

Emergency access accounts keep permanent Global Administrator and are outside this model.

## Entitlement management

| Package | Catalog | Requestors | Approval | Duration | Review |
|---|---|---|---|---|---|
| `ap-global-administrators`, `ap-privileged-role-administrators`, `ap-privileged-authentication-administrators` | privileged-access | `persona-admins` | `pim-approvers` | 90 days | quarterly by approvers |
| `ap-developers` | workforce | all members | manager | 180 days | quarterly by manager |
| `ap-external-partners` | partners | existing directory users and guests | `governance-partner-sponsors` | 90 days, no extension | quarterly by sponsors |

## Access reviews

- Tier-0 groups: monthly, 7-day window, deny and auto-apply when unreviewed.
- Tier-1/Tier-2 groups: quarterly, deny and auto-apply.
- Emergency access exclusion group and service accounts: quarterly, **no default decision,
  no auto-apply** (an unanswered review must never remove an emergency account).
- Inactive guests (90 days) in every Microsoft 365 group: quarterly, reviewed by group owners.

## Lifecycle workflows

| Workflow | Trigger | Tasks |
|---|---|---|
| `joiner-pre-hire` | hire date - 7 days | Onboarding reminder to manager |
| `joiner-day-one` | hire date | Enable account, one-time TAP to manager, add to `users-new-hires`, welcome email |
| `mover-job-change` | `department` / `jobTitle` change | Notify manager |
| `leaver-last-day` | leave date | Disable, revoke tokens, remove access packages, groups and Teams, email manager |
| `leaver-post-offboarding` | leave date + N days | Remove licences, delete account |

Workflows are created with scheduling **off**; run them on demand and check the results
before setting `lifecycle_scheduling_enabled = true`.

## Dependencies

Groups resolved by display name from `10-entra-foundation`. `pim_eligible_members` takes
UPNs of dedicated admin accounts, resolved with `data "azuread_user"`.

Licensing: Microsoft Entra ID P2 (PIM, access reviews) and Microsoft Entra ID Governance
(lifecycle workflows, advanced entitlement management).

Graph permissions: `RoleManagement.ReadWrite.Directory`, `RoleManagementPolicy.ReadWrite.Directory`,
`RoleManagementPolicy.ReadWrite.AzureADGroup`, `PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup`,
`EntitlementManagement.ReadWrite.All`, `AccessReview.ReadWrite.All`,
`LifecycleWorkflows.ReadWrite.All`, `Group.Read.All`, `User.Read.All`.

## Outputs

`access_packages`, `access_review_definition_ids`, `lifecycle_workflow_ids`,
`directory_role_policy_ids`.
