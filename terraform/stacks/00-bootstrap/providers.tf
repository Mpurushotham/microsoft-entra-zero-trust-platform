# Operators bootstrap with Azure CLI; CI enables OIDC through ARM_USE_OIDC.
provider "azurerm" {
  features {}

  storage_use_azuread             = true
  resource_provider_registrations = "core"
  resource_providers_to_register = [
    "Microsoft.OperationalInsights",
    "Microsoft.OperationsManagement",
    "Microsoft.SecurityInsights",
    "Microsoft.Insights",
    "Microsoft.AADIAM",
  ]
}

provider "azuread" {}
