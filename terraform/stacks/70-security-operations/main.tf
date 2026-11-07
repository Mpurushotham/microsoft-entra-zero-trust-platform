data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "secops" {
  name = local.resource_group_name
}

module "sentinel" {
  source = "../../modules/secops-sentinel-workspace"

  name                = "${var.name_prefix}-${var.environment}-sentinel-law"
  resource_group_name = data.azurerm_resource_group.secops.name
  location            = data.azurerm_resource_group.secops.location
  retention_in_days   = var.retention_in_days
  daily_quota_gb      = var.daily_quota_gb
  tenant_id           = data.azurerm_client_config.current.tenant_id
  data_connectors     = var.data_connectors
  tags                = local.tags
}

module "entra_diagnostics" {
  source = "../../modules/secops-entra-diagnostics"

  name                       = "${var.name_prefix}-${var.environment}-entra-to-sentinel"
  log_analytics_workspace_id = module.sentinel.workspace_id
  log_categories             = var.entra_log_categories
}

module "analytics" {
  source = "../../modules/secops-sentinel-analytics"

  log_analytics_workspace_id = module.sentinel.workspace_id
  name_prefix                = var.name_prefix
  break_glass_upns           = var.break_glass_upns
  trusted_automation_names   = local.trusted_automation_names
  business_hours             = var.business_hours
  mfa_fatigue_threshold      = var.mfa_fatigue_threshold
  disabled_rules             = var.disabled_rules
}
