provider "azurerm" {
  features {}

  use_oidc            = true
  storage_use_azuread = true
  # The apply identity holds resource-group roles only; stack 00 registers the providers.
  resource_provider_registrations = "none"
}
