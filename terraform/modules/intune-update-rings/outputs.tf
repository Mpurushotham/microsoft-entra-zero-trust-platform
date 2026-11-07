output "ring_ids" {
  value = { for k, r in msgraph_resource.ring : k => r.id }
}

output "feature_update_profile_ids" {
  value = { for k, p in msgraph_resource.feature_update : k => p.id }
}
