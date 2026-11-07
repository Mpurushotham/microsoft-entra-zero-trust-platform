output "policy_ids" {
  description = "Settings catalog policy IDs keyed by policy key."
  value       = { for k, p in msgraph_resource.policy : k => p.id }
}
