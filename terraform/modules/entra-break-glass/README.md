# entra-break-glass

Emergency access ("break-glass") accounts built to Microsoft's
[emergency access account guidance](https://learn.microsoft.com/entra/identity/role-based-access-control/security-emergency-access).

## What it creates

| Resource | Detail |
|---|---|
| Two or more cloud-only users | UPN on the tenant's initial `*.onmicrosoft.com` domain, so sign-in never depends on federation, DNS, Connect/Cloud Sync or on-premises AD |
| Random passwords | `random_password`, 64 characters by default, never expire. Exposed only through the sensitive `initial_passwords` output |
| Permanent Global Administrator | Active (not PIM-eligible) assignment, so the account works when PIM, MFA providers or approvers are unavailable |
| Exclusion group | `<prefix>-<env>-ca-exclude-emergency-access`, role-assignable so only Privileged Role Administrators can change it. Stack `20-entra-conditional-access` excludes it from every policy |

## After the first apply

1. On a trusted workstation, read `terraform output -json initial_passwords`, split each
   password between two custodians and store the halves in separate sealed locations.
2. Register a **FIDO2 security key** (two keys per account, stored in separate physical
   locations) for each account. Microsoft recommends phishing-resistant credentials for
   emergency accounts; passwords are the fallback, not the primary method.
3. Validate each account at least every 90 days and after any change to CA, MFA or
   staff with custody. Record the test in the break-glass runbook.
4. Confirm the sign-in alert is live (below).

## Monitoring

Every sign-in by these accounts must page the security on-call. The `sign_in_alert_kql`
output is consumed by stack `70-security-operations` to build a scheduled analytics rule
(run every 5 minutes, look back 5 minutes, severity High). Also alert on:

- membership changes to the exclusion group (`AuditLogs`, `Add member to group`),
- password or authentication-method changes on the accounts.

## State handling

The passwords are stored in Terraform state. The state backend must be the private,
Entra-auth-only storage account from `00-bootstrap`, with access limited to the
deployment identity and break-glass custodians. `password` is ignored after creation so a
rotation done out of band is not reverted; rotate deliberately with `-replace` on the
`random_password` instance.

## Inputs

| Name | Type | Default |
|---|---|---|
| `name_prefix` | string | required |
| `environment` | string (`dev`/`prod`) | required |
| `account_aliases` | list(string), min 2 | `["ea-admin-01", "ea-admin-02"]` |
| `usage_location` | string | `"US"` |
| `password_length` | number (32-256) | `64` |
| `assign_global_administrator` | bool | `true` |

## Outputs

| Name | Sensitive |
|---|---|
| `exclusion_group_object_id`, `exclusion_group_display_name` | no |
| `accounts` (UPN and object ID per alias) | no |
| `initial_passwords` | **yes** |
| `sign_in_alert_kql` | no |

## Example

```hcl
module "break_glass" {
  source      = "../../modules/entra-break-glass"
  name_prefix = "zt"
  environment = "prod"
}
```
