# entra-lifecycle-workflows

Microsoft Entra ID Governance **lifecycle workflows** for joiner, mover and leaver
automation, created through Microsoft Graph v1.0
(`identityGovernance/lifecycleWorkflows/workflows`). Follows Microsoft's
[lifecycle workflows guidance](https://learn.microsoft.com/entra/id-governance/what-are-lifecycle-workflows).

## Inputs shape

Each workflow sets a `category`, an OData-style `scope_rule` on user attributes
(for example `(department eq 'Finance') and (employeeType eq 'Employee')`) and a trigger:

- **time based**: `time_based_attribute` = `employeeHireDate`, `employeeLeaveDateTime` or
  `createdDateTime`, plus `offset_in_days` (negative runs before the date);
- **attribute change** (movers): `changed_attributes`, for example `["department", "jobTitle"]`.

Tasks reference Microsoft's built-in task definition IDs; `arguments` is a map of task
parameters (for example `groupID`, `tapLifetimeMinutes`, `accessPackageId`).

## Common task definition IDs

| Task | ID |
|---|---|
| Enable user account | `6fc52c9d-398b-4305-9763-15f42c1676fc` |
| Send welcome email | `70b29d51-b59a-4773-9280-8841dfd3f2ea` |
| Generate TAP and send email | `1b555e50-7f65-41d5-b514-5894a026d10d` |
| Add user to groups | `22085229-5809-45e8-97fd-270d28d66910` |
| Request user access package assignment | `c1ec1e76-f374-4375-aaa6-0bb6bd4c60be` |
| Send email to notify manager of user move | `aab41899-9972-422a-9d97-f626014578b7` |
| Disable user account | `1dfdfcc7-52fa-4c2e-bf3a-e3919cc12950` |
| Revoke all refresh tokens | `509589a4-0466-4471-829e-49c5e502bdee` |
| Remove user from all groups | `b3a31406-2a15-4c9a-b25b-a658fa5f07fc` |
| Remove user from all Teams | `81f7b200-2816-4b3b-8c5d-dc556f07b024` |
| Remove all access package assignments | `42ae2956-193d-4f39-be06-691b8ac4fa1d` |
| Remove all licenses | `8fa97d28-3e52-4985-b3a9-a1126f9b8b4e` |
| Send email on user's last day | `9c0a1eaf-5bda-4392-9d9e-6e155bb57411` |
| Delete user account | `8d18588d-9ad3-4c0f-99d0-ec215f0e3dff` |

## Behaviour to know

- Changing tasks, trigger, scope or category **replaces** the workflow (Graph only allows
  those through `createNewVersion`). Run history stays in the deleted workflow, which Entra
  keeps in *Deleted workflows* for 30 days.
- `scheduling_enabled = false` by default: run workflows on demand and check the run report
  before letting the scheduler act on real users.
- Users need `employeeHireDate` / `employeeLeaveDateTime` populated (HR-driven provisioning,
  Entra Cloud Sync attribute mapping or Graph) for time-based triggers to fire.
- Requires Microsoft Entra ID Governance. The deployment identity needs
  `LifecycleWorkflows.ReadWrite.All`.

## Outputs

| Name | Description |
|---|---|
| `workflow_ids` | `{ key => workflow id }` |
