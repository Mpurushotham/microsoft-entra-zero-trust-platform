output "policy_ids" {
  description = "Compliance policy IDs keyed by platform."
  value       = { for k, p in msgraph_resource.policy : k => p.id }
}

output "policy_names" {
  value = { for k, p in local.policies : k => p.displayName }
}
