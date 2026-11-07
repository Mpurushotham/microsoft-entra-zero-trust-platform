output "policy_ids" {
  description = "Endpoint security policy IDs keyed by policy key."
  value       = { for k, p in msgraph_resource.policy : k => p.id }
}

output "asr_rule_modes" {
  value = local.asr_rules
}
