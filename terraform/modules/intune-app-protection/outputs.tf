output "policy_ids" {
  value = { for k, p in msgraph_resource.policy : k => p.id }
}

output "protection_level" {
  value = var.protection_level
}
