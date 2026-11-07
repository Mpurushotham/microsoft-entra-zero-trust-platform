# Tenant and client IDs come from ARM_TENANT_ID / ARM_CLIENT_ID in CI.
provider "azuread" {
  use_oidc = true
}

provider "msgraph" {
  use_oidc = true
}
