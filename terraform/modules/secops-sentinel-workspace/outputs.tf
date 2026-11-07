output "workspace_id" {
  description = "Log Analytics workspace resource ID, available only after Sentinel onboarding."
  value       = azurerm_sentinel_log_analytics_workspace_onboarding.this.workspace_id
}

output "workspace_name" {
  value = azurerm_log_analytics_workspace.this.name
}

output "workspace_customer_id" {
  value = azurerm_log_analytics_workspace.this.workspace_id
}

output "enabled_connectors" {
  value = sort([for k, v in var.data_connectors : k if v])
}
