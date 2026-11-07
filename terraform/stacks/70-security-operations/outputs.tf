output "log_analytics_workspace_id" {
  description = "Feed into stack 00 state_log_analytics_workspace_id to log state access."
  value       = module.sentinel.workspace_id
}

output "log_analytics_workspace_name" {
  value = module.sentinel.workspace_name
}

output "enabled_connectors" {
  value = module.sentinel.enabled_connectors
}

output "entra_log_categories" {
  value = module.entra_diagnostics.log_categories
}

output "analytics_rule_ids" {
  value = module.analytics.rule_ids
}
