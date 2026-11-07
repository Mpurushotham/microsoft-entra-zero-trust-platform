resource "azuread_group" "this" {
  for_each = var.groups

  display_name            = "${var.name_prefix}-${var.environment}-${each.key}"
  description             = each.value.description
  security_enabled        = true
  mail_enabled            = false
  prevent_duplicate_names = true
  assignable_to_role      = each.value.assignable_to_role
  types                   = each.value.dynamic_rule == null ? null : ["DynamicMembership"]
  # An empty set would strip the calling principal as owner.
  owners = length(concat(var.default_owner_object_ids, each.value.owner_object_ids)) > 0 ? distinct(concat(var.default_owner_object_ids, each.value.owner_object_ids)) : null

  dynamic "dynamic_membership" {
    for_each = each.value.dynamic_rule == null ? [] : [each.value.dynamic_rule]
    content {
      enabled = true
      rule    = dynamic_membership.value
    }
  }

  lifecycle {
    # Membership of assigned groups is owned by PIM, access packages and lifecycle workflows.
    ignore_changes = [members]
  }
}
