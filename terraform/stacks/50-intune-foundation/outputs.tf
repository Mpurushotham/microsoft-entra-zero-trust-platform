output "device_group_ids" {
  description = "Dynamic device group object IDs keyed by platform."
  value       = local.device_group_ids
}

output "windows_ring_pilot_group_id" {
  value = azuread_group.windows_ring_pilot.object_id
}

output "intune_users_group_id" {
  value = azuread_group.intune_users.object_id
}

output "intune_role_group_ids" {
  value = { for k, g in azuread_group.intune_role : k => g.object_id }
}

output "compliance_policy_ids" {
  value = module.compliance.policy_ids
}

output "configuration_policy_ids" {
  value = module.configuration.policy_ids
}

output "endpoint_security_policy_ids" {
  value = module.endpoint_security.policy_ids
}

output "update_ring_ids" {
  value = module.update_rings.ring_ids
}

output "app_protection_policy_ids" {
  value = module.app_protection.policy_ids
}

output "scope_tag_ids" {
  value = module.rbac.scope_tag_ids
}
