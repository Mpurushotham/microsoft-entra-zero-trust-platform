output "wave_groups" {
  description = "Wave name to group object ID and display name; consumed by Start-StagedRolloutWave.ps1 and other stacks."
  value       = module.staged_rollout.wave_groups
}

output "feature_rollout_policy_ids" {
  value = module.staged_rollout.feature_rollout_policy_ids
}

output "enabled_waves" {
  value = module.staged_rollout.enabled_waves
}

output "migrated_applications" {
  value = module.app_migration.applications
}

output "saml_signing_certificate_thumbprints" {
  value = module.app_migration.saml_signing_certificate_thumbprints
}

output "cloud_managed_group_ids" {
  value = sort(tolist(var.cloud_managed_group_ids))
}
