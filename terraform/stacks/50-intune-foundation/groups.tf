resource "azuread_group" "device" {
  for_each = local.device_groups

  display_name            = "${local.prefix}-devices-${each.value.suffix}"
  description             = "Dynamic device group for Intune targeting (${each.value.suffix})."
  security_enabled        = true
  types                   = ["DynamicMembership"]
  prevent_duplicate_names = true

  dynamic_membership {
    enabled = true
    rule    = each.value.rule
  }
}

resource "azuread_group" "windows_ring_pilot" {
  display_name            = "${local.prefix}-devices-windows-ring-pilot"
  description             = "Assigned pilot devices that receive Windows quality and feature updates first."
  security_enabled        = true
  prevent_duplicate_names = true
}

resource "azuread_group" "intune_users" {
  display_name            = "${local.prefix}-users-intune"
  description             = "Users in scope for Intune enrollment restrictions and app protection."
  security_enabled        = true
  prevent_duplicate_names = true
}

resource "azuread_group" "intune_role" {
  for_each = local.rbac_groups

  display_name            = "${local.prefix}-intune-role-${each.value.suffix}"
  description             = "Members receive the Intune role \"${each.value.role}\"."
  security_enabled        = true
  prevent_duplicate_names = true
}

data "azuread_group" "intune_users" {
  for_each = toset(var.intune_user_group_names)

  display_name     = each.value
  security_enabled = true
}
