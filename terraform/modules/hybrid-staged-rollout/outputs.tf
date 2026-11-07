output "wave_groups" {
  description = "Wave name to group object ID and display name."
  value = {
    for wave, group in azuread_group.wave : wave => {
      object_id    = group.object_id
      display_name = group.display_name
    }
  }
}

output "feature_rollout_policy_ids" {
  description = "Feature name to featureRolloutPolicy ID."
  value       = { for feature, policy in msgraph_resource.feature_rollout_policy : feature => policy.id }
}

output "enabled_waves" {
  value = var.enabled_waves
}
