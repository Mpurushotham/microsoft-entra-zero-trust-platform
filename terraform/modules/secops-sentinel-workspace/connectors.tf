# Every connector references the onboarding resource so Terraform orders them after Sentinel exists.
locals {
  sentinel_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.this.workspace_id
}

# The AzureActiveDirectory connector kind carries Entra ID Protection alerts into SecurityAlert.
resource "azurerm_sentinel_data_connector_azure_active_directory" "entra_id_protection" {
  count = var.data_connectors.entra_id_protection ? 1 : 0

  name                       = "entra-id-protection"
  log_analytics_workspace_id = local.sentinel_workspace_id
  tenant_id                  = var.tenant_id
}

resource "azurerm_sentinel_data_connector_microsoft_threat_protection" "defender_xdr" {
  count = var.data_connectors.defender_xdr ? 1 : 0

  name                       = "defender-xdr"
  log_analytics_workspace_id = local.sentinel_workspace_id
  tenant_id                  = var.tenant_id
}

resource "azurerm_sentinel_data_connector_office_365" "this" {
  count = var.data_connectors.office_365 ? 1 : 0

  name                       = "office-365"
  log_analytics_workspace_id = local.sentinel_workspace_id
  tenant_id                  = var.tenant_id
  exchange_enabled           = true
  sharepoint_enabled         = true
  teams_enabled              = true
}

resource "azurerm_sentinel_data_connector_azure_advanced_threat_protection" "defender_for_identity" {
  count = var.data_connectors.defender_for_identity ? 1 : 0

  name                       = "defender-for-identity"
  log_analytics_workspace_id = local.sentinel_workspace_id
  tenant_id                  = var.tenant_id
}

resource "azurerm_sentinel_data_connector_microsoft_cloud_app_security" "defender_for_cloud_apps" {
  count = var.data_connectors.defender_for_cloud_apps ? 1 : 0

  name                       = "defender-for-cloud-apps"
  log_analytics_workspace_id = local.sentinel_workspace_id
  tenant_id                  = var.tenant_id
  alerts_enabled             = true
  discovery_logs_enabled     = true
}

resource "azurerm_sentinel_data_connector_microsoft_defender_advanced_threat_protection" "defender_for_endpoint" {
  count = var.data_connectors.defender_for_endpoint ? 1 : 0

  name                       = "defender-for-endpoint"
  log_analytics_workspace_id = local.sentinel_workspace_id
  tenant_id                  = var.tenant_id
}

resource "azurerm_sentinel_data_connector_microsoft_threat_intelligence" "this" {
  count = var.data_connectors.threat_intelligence ? 1 : 0

  name                                         = "microsoft-defender-threat-intelligence"
  log_analytics_workspace_id                   = local.sentinel_workspace_id
  tenant_id                                    = var.tenant_id
  microsoft_emerging_threat_feed_lookback_date = var.threat_intelligence_lookback_date
}
