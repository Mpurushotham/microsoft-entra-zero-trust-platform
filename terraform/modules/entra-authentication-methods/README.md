# entra-authentication-methods

Tenant Authentication methods policy and custom authentication strengths, following
Microsoft's [passwordless deployment](https://learn.microsoft.com/entra/identity/authentication/how-to-plan-prerequisites-phishing-resistant-passwordless-authentication)
and [authentication methods management](https://learn.microsoft.com/entra/identity/authentication/concept-authentication-methods-manage) guidance.

## What it configures

| Method / setting | Default | Graph endpoint (v1.0) |
|---|---|---|
| Passkeys (FIDO2) | Enabled for all users, self-service registration, default passkey profile (device-bound and synced) | `.../authenticationMethodConfigurations/fido2` |
| Microsoft Authenticator | Enabled, push + passwordless (`any`), app name and geographic location shown in the prompt | `.../microsoftAuthenticator` |
| Temporary Access Pass | Enabled, one-time use, 60 min default, 8 h maximum, 12 characters | `.../temporaryAccessPass` |
| SMS | Disabled | `.../sms` |
| Voice call | Disabled | `.../voice` |
| Registration campaign | Prompts users without Authenticator, 1-day snooze, emergency access excluded | `policies/authenticationMethodsPolicy` |
| Policy migration | Left alone unless `complete_policy_migration = true` | `policies/authenticationMethodsPolicy` |
| Authentication strengths | Created from `authentication_strengths` | `azuread_authentication_strength_policy` |

Number matching is enforced by Entra ID for every Authenticator push notification and is
no longer a configurable property, so it is not set here. Application name and location
context are the remaining anti-MFA-fatigue controls and are enabled.

## Behaviour to know

- These are singleton tenant settings managed with `msgraph_update_resource` (PATCH).
  Destroying the module does **not** revert them; apply the desired values before removing it.
- Disabling SMS/voice blocks users whose only method is SMS. Run the registration campaign
  and check the *Authentication methods activity* report before applying in production.
- Set `complete_policy_migration = true` only after the legacy per-user MFA and SSPR method
  settings have been reconciled with this policy.
- If the tenant has not opted in to passkey profiles, set `fido2.use_passkey_profiles = false`
  to use the legacy `keyRestrictions`/`isAttestationEnforced` properties.

## Inputs

| Name | Type | Default |
|---|---|---|
| `name_prefix`, `environment` | string | required |
| `excluded_group_ids` | list(string) | `[]` |
| `fido2` | object | see `variables.tf` |
| `microsoft_authenticator` | object | see `variables.tf` |
| `temporary_access_pass` | object | see `variables.tf` |
| `disable_sms`, `disable_voice` | bool | `true` |
| `registration_campaign` | object | enabled, Authenticator |
| `complete_policy_migration` | bool | `false` |
| `authentication_strengths` | map(object({ description, allowed_combinations })) | `{}` |

## Outputs

| Name | Description |
|---|---|
| `authentication_strengths` | `{ key => { id, object_id, display_name } }` |

## Example

```hcl
module "authentication_methods" {
  source             = "../../modules/entra-authentication-methods"
  name_prefix        = "zt"
  environment        = "prod"
  excluded_group_ids = [module.break_glass.exclusion_group_object_id]
  authentication_strengths = {
    "phishing-resistant-admins" = {
      description          = "FIDO2, Windows Hello for Business or certificate MFA."
      allowed_combinations = ["fido2", "windowsHelloForBusiness", "x509CertificateMultiFactor"]
    }
  }
}
```
