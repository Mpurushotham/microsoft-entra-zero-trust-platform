resource "azuread_directory_role_eligibility_schedule_request" "this" {
  for_each = var.role_eligibilities

  role_definition_id = each.value.role_template_id
  principal_id       = each.value.principal_object_id
  directory_scope_id = each.value.directory_scope_id
  justification      = each.value.justification
}

resource "azuread_directory_role_assignment" "this" {
  for_each = var.role_assignments

  role_id             = each.value.role_template_id
  principal_object_id = each.value.principal_object_id
  directory_scope_id  = each.value.directory_scope_id
}
