locals {
  prefix = "${var.name_prefix}-${var.environment}"

  group_tag_groups = {
    for k, p in var.autopilot_profiles : k => {
      display_name = "${local.prefix}-devices-autopilot-${lower(p.group_tag)}"
      rule         = "(device.devicePhysicalIds -any (_ -eq \"[OrderID]:${p.group_tag}\"))"
    }
  }
}
