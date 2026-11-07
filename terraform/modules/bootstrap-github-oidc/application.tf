resource "azuread_application_registration" "this" {
  display_name                 = var.display_name
  description                  = var.description
  sign_in_audience             = "AzureADMyOrg"
  service_management_reference = var.service_management_reference
}

resource "azuread_application_owner" "this" {
  for_each = var.owner_object_ids

  application_id  = azuread_application_registration.this.id
  owner_object_id = each.value
}

resource "azuread_service_principal" "this" {
  client_id                    = azuread_application_registration.this.client_id
  app_role_assignment_required = true
  owners                       = var.owner_object_ids
  notes                        = "GitHub Actions workload identity for ${var.github_repository}. No client secrets: federated credentials only."
}

resource "azuread_application_federated_identity_credential" "github" {
  for_each = var.github_subjects

  application_id = azuread_application_registration.this.id
  display_name   = substr(replace("github-${each.value}", "/[^A-Za-z0-9-]/", "-"), 0, 120)
  description    = "GitHub Actions OIDC: repo:${var.github_repository}:${each.value}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repository}:${each.value}"
}
