resource "azurerm_storage_account" "state" {
  # checkov:skip=CKV_AZURE_33:Queue service is unused; state lives in blob only.
  # checkov:skip=CKV2_AZURE_1:Microsoft-managed keys with infrastructure (double) encryption; CMK adds a Key Vault dependency before state exists.
  # checkov:skip=CKV2_AZURE_33:Private endpoint is optional because GitHub-hosted runners have no private path; see public_network_access.
  # checkov:skip=CKV_AZURE_59:Public endpoint is a documented choice for GitHub-hosted runners; shared keys are disabled so only Entra ID principals with RBAC can read.
  # checkov:skip=CKV_AZURE_35:Default action is a variable; Deny breaks GitHub-hosted runners without private connectivity.
  # checkov:skip=CKV_AZURE_206:Replication is a variable (ZRS default, GZRS recommended for prod).
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = var.replication_type
  access_tier              = "Hot"

  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  shared_access_key_enabled         = false
  default_to_oauth_authentication   = true
  allow_nested_items_to_be_public   = false
  cross_tenant_replication_enabled  = false
  allowed_copy_scope                = "AAD"
  infrastructure_encryption_enabled = true
  local_user_enabled                = false
  sftp_enabled                      = false
  public_network_access             = var.public_network_access

  blob_properties {
    versioning_enabled            = true
    change_feed_enabled           = true
    change_feed_retention_in_days = var.soft_delete_retention_days
    last_access_time_enabled      = false

    delete_retention_policy {
      days = var.soft_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.soft_delete_retention_days
    }
  }

  network_rules {
    default_action = var.network_default_action
    bypass         = ["AzureServices"]
    ip_rules       = [for ip in var.allowed_ip_ranges : trimsuffix(ip, "/32")]
  }

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "state" {
  # checkov:skip=CKV2_AZURE_21:Blob logging is set by azurerm_monitor_diagnostic_setting.state_blob once the secops workspace exists.
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_management_lock" "state" {
  count = var.delete_lock_enabled ? 1 : 0

  name       = "${var.storage_account_name}-do-not-delete"
  scope      = azurerm_storage_account.state.id
  lock_level = "CanNotDelete"
  notes      = "Holds Terraform state for every platform stack. Remove only through a reviewed change."
}

# Optional on first run: the Log Analytics workspace is created later by stack 70.
resource "azurerm_monitor_diagnostic_setting" "state_blob" {
  count = var.log_analytics_workspace_id == null ? 0 : 1

  name                       = "state-blob-to-secops"
  target_resource_id         = "${azurerm_storage_account.state.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }
}
