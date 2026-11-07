locals {
  prefix = "${var.name_prefix}-${var.environment}"

  device_groups = {
    windows_corporate    = { suffix = "windows-corporate", rule = "(device.deviceOSType -eq \"Windows\") and (device.deviceOwnership -eq \"Company\")" }
    macos                = { suffix = "macos", rule = "(device.deviceOSType -eq \"MacMDM\")" }
    ios                  = { suffix = "ios", rule = "(device.deviceOSType -eq \"iPhone\") or (device.deviceOSType -eq \"iPad\")" }
    android_corporate    = { suffix = "android-corporate", rule = "(device.deviceOSType -eq \"AndroidEnterprise\")" }
    android_work_profile = { suffix = "android-work-profile", rule = "(device.deviceOSType -eq \"AndroidForWork\")" }
  }

  rbac_groups = {
    help_desk         = { suffix = "helpdesk", role = "Help Desk Operator", scope_type = "resourceScope" }
    endpoint_security = { suffix = "endpoint-security", role = "Endpoint Security Manager", scope_type = "allDevicesAndLicensedUsers" }
    policy_profile    = { suffix = "policy-profile", role = "Policy and Profile manager", scope_type = "allDevicesAndLicensedUsers" }
    read_only         = { suffix = "read-only", role = "Read Only Operator", scope_type = "allDevicesAndLicensedUsers" }
  }

  device_group_ids = { for k, g in azuread_group.device : k => g.object_id }
  windows_ids      = [azuread_group.device["windows_corporate"].object_id]

  user_group_ids = concat(
    [azuread_group.intune_users.object_id],
    [for g in data.azuread_group.intune_users : g.object_id],
  )
}
