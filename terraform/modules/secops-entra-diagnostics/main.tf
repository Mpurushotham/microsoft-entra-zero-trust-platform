# Tenant-scoped: the deploying identity needs the Entra Security Administrator role.
resource "azurerm_monitor_aad_diagnostic_setting" "this" {
  name                       = var.name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  storage_account_id         = var.archive_storage_account_id

  dynamic "enabled_log" {
    for_each = var.log_categories

    content {
      category = enabled_log.value
    }
  }
}
