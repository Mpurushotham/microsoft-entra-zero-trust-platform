# bootstrap-github-oidc

Entra ID app registration and service principal that GitHub Actions signs in as through workload identity
federation. No client secret or certificate is ever created.

Creates:

- `azuread_application_registration` (single tenant) with owners
- `azuread_service_principal` with `app_role_assignment_required = true`
- One `azuread_application_federated_identity_credential` per GitHub subject
  (issuer `https://token.actions.githubusercontent.com`, audience `api://AzureADTokenExchange`)
- Microsoft Graph application permissions: the role IDs come from the Microsoft Graph service principal's
  `app_role_ids` map, declared with `azuread_application_api_access` and admin-consented with
  `azuread_app_role_assignment`. An unknown permission name fails the plan with a clear message.
- Optional Entra directory role assignments (tenant scope) and Azure RBAC role assignments

## Subjects

| GitHub context | Subject suffix |
|---|---|
| Job with `environment: prod` | `environment:prod` |
| `pull_request` event without an environment | `pull_request` |
| Push or schedule on `main` without an environment | `ref:refs/heads/main` |

## Inputs

| Name | Type | Default |
|---|---|---|
| `display_name` | string | required |
| `description` | string | `null` |
| `github_repository` | string | required, `owner/name` |
| `github_subjects` | set(string) | required, 1 to 20 |
| `graph_app_roles` | set(string) | `[]` |
| `directory_role_template_ids` | set(string) | `[]` |
| `azure_role_assignments` | map(object({ scope, role_definition_name })) | `{}` |
| `owner_object_ids` | set(string) | required |
| `service_management_reference` | string | `null` |

## Outputs

`client_id`, `application_object_id`, `service_principal_object_id`, `federated_subjects`, `graph_app_roles`.

## Example

```hcl
module "github_apply_prod" {
  source            = "../../modules/bootstrap-github-oidc"
  display_name      = "zt-prod-github-apply"
  github_repository = "Mpurushotham/microsoft-entra-zero-trust-platform"
  github_subjects   = ["environment:prod"]
  graph_app_roles   = ["Policy.Read.All", "Policy.ReadWrite.ConditionalAccess"]
  owner_object_ids  = ["00000000-0000-0000-0000-000000000000"]
}
```
