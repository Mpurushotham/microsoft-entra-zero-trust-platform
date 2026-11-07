resource "azuread_group" "exclusion" {
  display_name            = "${var.name_prefix}-${var.environment}-ca-exclude-emergency-access"
  description             = "Emergency access accounts. Excluded from every Conditional Access policy. Membership changes must raise a high-severity alert."
  security_enabled        = true
  mail_enabled            = false
  prevent_duplicate_names = true
  # Restricts membership changes to Privileged Role Administrators.
  assignable_to_role = true
  visibility         = "Private"
}

resource "azuread_group_member" "exclusion" {
  for_each = azuread_user.this

  group_object_id  = azuread_group.exclusion.object_id
  member_object_id = each.value.object_id
}
