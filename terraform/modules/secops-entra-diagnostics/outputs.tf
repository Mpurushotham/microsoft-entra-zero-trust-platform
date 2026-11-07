output "id" {
  value = azurerm_monitor_aad_diagnostic_setting.this.id
}

output "log_categories" {
  value = sort(tolist(var.log_categories))
}
