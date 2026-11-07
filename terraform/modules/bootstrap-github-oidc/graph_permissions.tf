data "azuread_application_published_app_ids" "well_known" {}

data "azuread_service_principal" "msgraph" {
  client_id = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]
}

locals {
  unknown_graph_roles = setsubtract(var.graph_app_roles, keys(data.azuread_service_principal.msgraph.app_role_ids))
}

# Keeps the portal "API permissions" blade accurate; consent comes from the role assignments below.
resource "azuread_application_api_access" "msgraph" {
  count = length(var.graph_app_roles) > 0 ? 1 : 0

  application_id = azuread_application_registration.this.id
  api_client_id  = data.azuread_application_published_app_ids.well_known.result["MicrosoftGraph"]
  role_ids       = [for r in var.graph_app_roles : data.azuread_service_principal.msgraph.app_role_ids[r]]

  lifecycle {
    precondition {
      condition     = length(local.unknown_graph_roles) == 0
      error_message = "Unknown Microsoft Graph application permissions: ${join(", ", local.unknown_graph_roles)}."
    }
  }
}

resource "azuread_app_role_assignment" "msgraph" {
  for_each = var.graph_app_roles

  app_role_id         = data.azuread_service_principal.msgraph.app_role_ids[each.value]
  principal_object_id = azuread_service_principal.this.object_id
  resource_object_id  = data.azuread_service_principal.msgraph.object_id
}

resource "azuread_directory_role_assignment" "this" {
  for_each = var.directory_role_template_ids

  role_id             = each.value
  principal_object_id = azuread_service_principal.this.object_id
  directory_scope_id  = "/"
}
