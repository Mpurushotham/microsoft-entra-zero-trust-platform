output "emergency_access_group" {
  value = {
    object_id    = module.break_glass.exclusion_group_object_id
    display_name = module.break_glass.exclusion_group_display_name
  }
}

output "emergency_access_accounts" {
  value = module.break_glass.accounts
}

output "emergency_access_initial_passwords" {
  description = "One-time hand-off only. Never print in CI logs."
  value       = module.break_glass.initial_passwords
  sensitive   = true
}

output "emergency_access_sign_in_kql" {
  value = module.break_glass.sign_in_alert_kql
}

output "groups" {
  description = "Object ID and display name per group key. Other stacks resolve these by display name."
  value       = module.groups.groups
}

output "administrative_units" {
  value = module.administrative_units.administrative_units
}

output "named_locations" {
  value = module.named_locations.locations
}

output "authentication_strengths" {
  value = module.authentication_methods.authentication_strengths
}
