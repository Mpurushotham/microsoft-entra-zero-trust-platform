output "autopilot_all_group_id" {
  value = azuread_group.autopilot_all.object_id
}

output "group_tag_group_ids" {
  description = "Dynamic device group object IDs keyed by profile name."
  value       = { for k, g in azuread_group.group_tag : k => g.object_id }
}

output "group_tags" {
  description = "Group tag to use with Import-AutopilotDevices.ps1 for each profile."
  value       = { for k, p in var.autopilot_profiles : k => p.group_tag }
}

output "device_preparation_group_id" {
  value = one(azuread_group.device_preparation[*].object_id)
}

output "deployment_profile_ids" {
  value = module.autopilot.deployment_profile_ids
}

output "enrollment_status_page_id" {
  value = module.autopilot.enrollment_status_page_id
}

output "required_app_ids" {
  value = module.autopilot.store_app_ids
}

output "android_zero_touch_dpc_extras" {
  value = var.android_zero_touch_enabled ? module.autopilot.android_zero_touch_dpc_extras : null
}

output "apple_ade_profile_id" {
  value = module.autopilot.apple_ade_profile_id
}
