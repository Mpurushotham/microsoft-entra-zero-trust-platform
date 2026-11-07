resource "azuread_administrative_unit" "this" {
  for_each = var.administrative_units

  display_name              = "${var.name_prefix}-${var.environment}-au-${each.key}"
  description               = each.value.description
  hidden_membership_enabled = each.value.hidden_membership_enabled
  prevent_duplicate_names   = true

  lifecycle {
    ignore_changes = [members]
  }
}

locals {
  members = merge([
    for au_key, au in var.administrative_units : {
      for member in au.member_object_ids : "${au_key}/${member}" => {
        au_key    = au_key
        object_id = member
      }
    }
  ]...)
}

resource "azuread_administrative_unit_member" "this" {
  for_each = local.members

  administrative_unit_object_id = azuread_administrative_unit.this[each.value.au_key].object_id
  member_object_id              = each.value.object_id
}

resource "azuread_directory_role_assignment" "scoped" {
  for_each = var.scoped_role_assignments

  role_id             = each.value.role_template_id
  principal_object_id = each.value.principal_object_id
  directory_scope_id  = "/administrativeUnits/${azuread_administrative_unit.this[each.value.administrative_unit_key].object_id}"
}
