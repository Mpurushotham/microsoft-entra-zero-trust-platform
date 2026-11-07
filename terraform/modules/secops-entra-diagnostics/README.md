# secops-entra-diagnostics

Tenant-level Entra ID diagnostic setting (`azurerm_monitor_aad_diagnostic_setting`) that streams identity logs to
the Sentinel workspace. This is what the Sentinel "Microsoft Entra ID" connector configures under the hood.

Default categories: `AuditLogs`, `SignInLogs`, `NonInteractiveUserSignInLogs`, `ServicePrincipalSignInLogs`,
`ManagedIdentitySignInLogs`, `ProvisioningLogs`, `RiskyUsers`, `UserRiskEvents`, `RiskyServicePrincipals`,
`ServicePrincipalRiskEvents`, `MicrosoftGraphActivityLogs`. Add `ADFSSignInLogs` during an AD FS migration
(needs Microsoft Entra Connect Health for AD FS).

Requirements:

- The deploying identity needs the Entra **Security Administrator** role. Azure RBAC does not apply to this
  tenant-scoped resource.
- Risk categories need Entra ID P2. `MicrosoftGraphActivityLogs` is billed per GB and can be large.
- A tenant allows five diagnostic settings. dev and prod in one tenant use two.

## Inputs

`name`, `log_analytics_workspace_id` (required); `log_categories` (defaults above, validated against the supported
list); `archive_storage_account_id` (optional long-term copy).

## Outputs

`id`, `log_categories`.
