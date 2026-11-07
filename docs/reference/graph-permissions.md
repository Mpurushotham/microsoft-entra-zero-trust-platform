# Graph permissions per stack

Each environment has two deployment identities created by `00-bootstrap`: a **plan** identity with read permissions and an **apply** identity with write permissions. Permissions are granted only for the stacks listed in the bootstrap variable `enabled_stacks`, so a tenant that does not use, for example, lifecycle workflows never grants `LifecycleWorkflows.ReadWrite.All`.

{% hint style="info" %}
The authoritative map is `stack_permissions` in `terraform/stacks/00-bootstrap/locals.tf`, and the granted set is printed by the `graph_permissions` output. This page mirrors it for review; update both together.
{% endhint %}

## Microsoft Graph application permissions

| Stack | Plan identity (read) | Apply identity (write) |
|---|---|---|
| `00-bootstrap` | `Application.Read.All`, `Directory.Read.All`, `RoleManagement.Read.Directory` | No additional permissions; identity and permission changes are applied by an elevated operator, so the pipeline can never grant itself rights |
| `10-entra-foundation` | `AdministrativeUnit.Read.All`, `CustomSecAttributeDefinition.Read.All`, `Group.Read.All`, `OrganizationalBranding.Read.All`, `Policy.Read.All`, `User.Read.All` | `AdministrativeUnit.ReadWrite.All`, `CustomSecAttributeDefinition.ReadWrite.All`, `Group.ReadWrite.All`, `OrganizationalBranding.ReadWrite.All`, `Policy.Read.All`, `Policy.ReadWrite.AuthenticationMethod`, `Policy.ReadWrite.ConditionalAccess`, `RoleManagement.ReadWrite.Directory`, `User.ReadWrite.All` |
| `20-entra-conditional-access` | `Application.Read.All`, `Group.Read.All`, `Policy.Read.All`, `User.Read.All` | `Application.Read.All`, `Group.Read.All`, `Policy.Read.All`, `Policy.ReadWrite.ConditionalAccess`, `User.Read.All` |
| `30-entra-governance` | `AccessReview.Read.All`, `EntitlementManagement.Read.All`, `Group.Read.All`, `LifecycleWorkflows.Read.All`, `PrivilegedAssignmentSchedule.Read.AzureADGroup`, `PrivilegedEligibilitySchedule.Read.AzureADGroup`, `RoleManagement.Read.Directory`, `RoleManagementPolicy.Read.AzureADGroup`, `RoleManagementPolicy.Read.Directory` | `AccessReview.ReadWrite.All`, `EntitlementManagement.ReadWrite.All`, `Group.ReadWrite.All`, `LifecycleWorkflows.ReadWrite.All`, `PrivilegedAssignmentSchedule.ReadWrite.AzureADGroup`, `PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup`, `RoleManagement.ReadWrite.Directory`, `RoleManagementPolicy.ReadWrite.AzureADGroup`, `RoleManagementPolicy.ReadWrite.Directory` |
| `40-hybrid-migration` | `Application.Read.All`, `Directory.Read.All`, `Domain.Read.All`, `Group.Read.All`, `OnPremDirectorySynchronization.Read.All`, `Policy.Read.All` | `Application.ReadWrite.OwnedBy`, `Directory.Read.All`, `Domain.Read.All`, `Group.ReadWrite.All`, `OnPremDirectorySynchronization.Read.All`, `Policy.ReadWrite.FeatureRollout` |
| `50-intune-foundation` | `DeviceManagementApps.Read.All`, `DeviceManagementConfiguration.Read.All`, `DeviceManagementRBAC.Read.All`, `DeviceManagementServiceConfig.Read.All`, `Group.Read.All` | `DeviceManagementApps.ReadWrite.All`, `DeviceManagementConfiguration.ReadWrite.All`, `DeviceManagementRBAC.ReadWrite.All`, `DeviceManagementServiceConfig.ReadWrite.All`, `Group.ReadWrite.All` |
| `60-intune-autopilot-zero-touch` | `Application.Read.All`, `DeviceManagementApps.Read.All`, `DeviceManagementConfiguration.Read.All`, `DeviceManagementServiceConfig.Read.All`, `Group.Read.All` | `Application.Read.All`, `DeviceManagementApps.ReadWrite.All`, `DeviceManagementConfiguration.ReadWrite.All`, `DeviceManagementServiceConfig.ReadWrite.All`, `Group.ReadWrite.All` |
| `70-security-operations` | None | None; uses a directory role instead (below) |

## Directory roles and Azure RBAC

| Identity | Assignment | Scope | Reason |
|---|---|---|---|
| Apply | Security Administrator (directory role) | Tenant | Entra ID diagnostic settings and tenant-level Sentinel connectors, only when `70-security-operations` is enabled |
| Apply | Storage Blob Data Contributor | State container | Read and write state |
| Apply | Log Analytics Contributor, Microsoft Sentinel Contributor | Security operations resource group | Workspace, Sentinel, rules |
| Plan | Reader | Subscription | Plan Azure resources |
| Plan | Storage Blob Data Reader | State container | Read state for plan |

{% hint style="warning" %}
Application permissions such as `RoleManagement.ReadWrite.Directory` and `Policy.ReadWrite.ConditionalAccess` are tier-0. Treat the apply identities as tier-0 assets: no secrets, federated credentials only to the protected environment, owners limited to the platform operators, and a quarterly review of granted permissions.
{% endhint %}

## Script permissions

PowerShell scripts run interactively as a human with delegated Microsoft Graph scopes, not as the CI identities. Each script lists its scopes in its help block, for example `Convert-DomainToManaged.ps1` uses `Domain.ReadWrite.All`, `Directory.Read.All`, `Organization.Read.All` and `OnPremDirectorySynchronization.Read.All`.

## References

* [Microsoft Graph permissions reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
* [Microsoft Entra built-in roles](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference)
* [Workload identity federation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation)
