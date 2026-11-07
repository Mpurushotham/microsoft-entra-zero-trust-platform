resource "azurerm_role_assignment" "this" {
  for_each = var.azure_role_assignments

  scope                            = each.value.scope
  role_definition_name             = each.value.role_definition_name
  principal_id                     = azuread_service_principal.this.object_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
  description                      = "${var.display_name}: ${each.key}"
}
