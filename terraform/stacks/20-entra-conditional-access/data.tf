data "azuread_group" "emergency_access" {
  display_name     = "${local.name}-ca-exclude-emergency-access"
  security_enabled = true
}

data "azuread_group" "service_accounts" {
  display_name     = "${local.name}-persona-service-accounts"
  security_enabled = true
}

data "azuread_named_location" "blocked_countries" {
  display_name = "${local.name}-nl-blocked-countries"
}

data "azuread_authentication_strength_policy" "phishing_resistant_admins" {
  display_name = "${local.name}-as-phishing-resistant-admins"
}

data "azuread_authentication_strength_policy" "security_info_registration" {
  display_name = "${local.name}-as-security-info-registration"
}
