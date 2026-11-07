resource "azuread_group" "autopilot_all" {
  display_name            = "${local.prefix}-devices-autopilot-all"
  description             = "Every Windows Autopilot registered device (ZTDId present)."
  security_enabled        = true
  types                   = ["DynamicMembership"]
  prevent_duplicate_names = true

  dynamic_membership {
    enabled = true
    rule    = "(device.devicePhysicalIDs -any (_ -startsWith \"[ZTDId]\"))"
  }
}

resource "azuread_group" "group_tag" {
  for_each = local.group_tag_groups

  display_name            = each.value.display_name
  description             = "Autopilot devices imported with group tag for profile ${each.key}."
  security_enabled        = true
  types                   = ["DynamicMembership"]
  prevent_duplicate_names = true

  dynamic_membership {
    enabled = true
    rule    = each.value.rule
  }
}

data "azuread_service_principal" "intune_provisioning_client" {
  count = var.enable_device_preparation_group ? 1 : 0

  client_id = var.intune_provisioning_client_app_id
}

# Device preparation adds devices to this group at enrollment, which requires the provisioning client as owner.
resource "azuread_group" "device_preparation" {
  count = var.enable_device_preparation_group ? 1 : 0

  display_name            = "${local.prefix}-devices-autopilot-device-preparation"
  description             = "Assigned group populated by Windows Autopilot device preparation policies."
  security_enabled        = true
  prevent_duplicate_names = true
  owners                  = [data.azuread_service_principal.intune_provisioning_client[0].object_id]
}
