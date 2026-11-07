# 10-entra-foundation

Tenant identity baseline for Microsoft Entra ID, aligned with the identity pillar of
Microsoft's [Zero Trust deployment guidance](https://learn.microsoft.com/security/zero-trust/deploy/identity).
Deploy before `20-entra-conditional-access` and `30-entra-governance`, which resolve the
objects created here by display name.

## What it deploys

| Module | Result |
|---|---|
| `entra-break-glass` | Two cloud-only emergency access accounts on `*.onmicrosoft.com`, permanent Global Administrator, random 64-character passwords (sensitive output), role-assignable CA exclusion group |
| `entra-groups` | Persona, privileged access (`pim-*`), and governance groups (Intune device groups live in stacks 50 and 60) |
| `entra-administrative-units` | `users-standard`, `devices-corporate`, `tier0-accounts`; Helpdesk Administrator scoped to `users-standard` for `pim-helpdesk-administrators` |
| `entra-named-locations` | Trusted corporate egress ranges, allowed countries, blocked countries |
| `entra-authentication-methods` | Passkeys (FIDO2), Microsoft Authenticator with app name and location context, one-time TAP, SMS and voice disabled, registration campaign, three custom authentication strengths |
| `entra-custom-security-attributes` | Optional `ZeroTrust` attribute set (`enable_custom_security_attributes`) |

## Groups created (`<prefix>-<env>-<key>`)

| Key | Type | Consumed by |
|---|---|---|
| `ca-exclude-emergency-access` | assigned, role-assignable | every CA policy (exclusion), access reviews |
| `persona-internals` | dynamic users (members) | CA targeting, Intune user assignment |
| `persona-guests` | dynamic users (guests) | reporting |
| `persona-admins` | assigned, role-assignable | Tier-0 access package requestors |
| `persona-developers`, `persona-external-partners` | assigned | access packages |
| `persona-service-accounts` | assigned, role-assignable | CA200 exclusion, access review |
| `governance-partner-sponsors` | assigned | partner access approvals |
| `ca-pilot-users` | assigned | policy pilots |
| `users-new-hires` | assigned | joiner workflow, onboarding apps / ESP |
| `pim-approvers` and `pim-*` role groups | assigned, role-assignable | `30-entra-governance` |

## Prerequisites

- Microsoft Entra ID P1 (dynamic groups, named locations); P2 for risk-based policies later.
- Deployment identity Graph application permissions: `User.ReadWrite.All`,
  `Group.ReadWrite.All`, `RoleManagement.ReadWrite.Directory`,
  `AdministrativeUnit.ReadWrite.All`, `Policy.ReadWrite.ConditionalAccess`, `Policy.Read.All`,
  `Policy.ReadWrite.AuthenticationMethod`, `Domain.Read.All`, and
  `CustomSecAttributeDefinition.ReadWrite.All` when custom security attributes are enabled.

## Deploy

```bash
terraform init \
  -backend-config="resource_group_name=$TFSTATE_RG" \
  -backend-config="storage_account_name=$TFSTATE_SA" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=10-entra-foundation/dev.tfstate" \
  -backend-config="use_oidc=true" -backend-config="use_azuread_auth=true"
terraform plan -var-file=env/dev.tfvars -out=tfplan
```

## After the first apply

1. Hand off the emergency access passwords (`terraform output -json emergency_access_initial_passwords`)
   on a trusted workstation, then register FIDO2 keys for both accounts. See
   `modules/entra-break-glass/README.md`.
2. Replace the RFC 5737 placeholder egress ranges in `env/*.tfvars` with real ones.
3. Set *Devices > Device settings > Require MFA to register or join devices* to **No**;
   CA005 enforces this through Conditional Access instead.
4. Review the *Authentication methods activity* report before disabling SMS/voice in prod.

## Outputs

`emergency_access_group`, `emergency_access_accounts`, `emergency_access_initial_passwords`
(sensitive), `emergency_access_sign_in_kql`, `groups`, `administrative_units`,
`named_locations`, `authentication_strengths`.
