# hybrid-app-migration

Recreates AD FS relying party trusts as Microsoft Entra enterprise applications from a
data map, so app migration is reviewed as code and repeatable across environments.

## What it creates per application

| Protocol | Resources |
|---|---|
| `saml` | Application instantiated from a gallery template (or the non-gallery template `8adf8e6e-67b2-4cf2-a259-e3dc5476c621`), service principal with `preferred_single_sign_on_mode = "saml"`, token signing certificate set as the preferred signing key, optional claims mapping policy |
| `oidc` | Application registration with web redirect URIs (implicit grant off), enterprise service principal with `preferred_single_sign_on_mode = "oidc"`, optional claims mapping policy |
| both | Default-role app role assignments to the groups in `assignment_groups`; `app_role_assignment_required = true` unless overridden |

The AD FS RP identifier is written to the application `notes` field for traceability.

## Mapping AD FS concepts

| AD FS | Entra |
|---|---|
| Relying party identifier | `identifier_uris` (SAML entity ID) |
| SAML assertion consumer endpoint / WS-Fed endpoint | `redirect_uris` (reply URL) |
| Issuance transform rules (simple attribute pass-through) | `claims_schema` (claims mapping policy) |
| Issuance authorization rules | `assignment_groups` + Conditional Access |
| Access control policy (MFA, device) | Conditional Access, stack `20-entra-conditional-access` |
| Complex claim language rules | Not migrated automatically; flagged by `Get-ADFSRelyingPartyInventory.ps1` |

Credentials for OIDC confidential clients are not created here. Use certificates or federated
identity credentials issued outside Terraform state.

Identifier URIs on single-tenant apps should use a verified domain where possible; Entra rejects
some unverified hosts for newer apps.

## Inputs

| Name | Type | Default |
|---|---|---|
| `name_prefix` | string | `"zt"` |
| `environment` | string | n/a |
| `applications` | map(object) — see `variables.tf` | `{}` |

## Outputs

| Name | Description |
|---|---|
| `applications` | key → `{ client_id, service_principal_object_id, sso_mode, adfs_relying_party }` |
| `saml_signing_certificate_thumbprints` | key → thumbprint to give each SAML service provider at cutover |

## Example

```hcl
module "app_migration" {
  source      = "../../modules/hybrid-app-migration"
  environment = "dev"
  applications = {
    hr-portal = {
      display_name       = "hr-portal"
      protocol           = "saml"
      adfs_relying_party = "https://hr.contoso.com/saml"
      identifier_uris    = ["https://hr.contoso.com/saml"]
      redirect_uris      = ["https://hr.contoso.com/saml/acs"]
      assignment_groups  = { pilot = "00000000-0000-0000-0000-000000000000" }
    }
  }
}
```

Graph permission for the deploying identity: `Application.ReadWrite.All`,
`AppRoleAssignment.ReadWrite.All`, `Policy.ReadWrite.ApplicationConfiguration`.
