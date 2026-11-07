data "azurerm_subscription" "current" {}

data "azuread_directory_role_templates" "all" {}

resource "azurerm_resource_group" "state" {
  name     = local.state_resource_group_name
  location = var.location
  tags     = local.tags
}

module "state_storage" {
  source = "../../modules/bootstrap-state-storage"

  resource_group_name        = azurerm_resource_group.state.name
  location                   = azurerm_resource_group.state.location
  storage_account_name       = var.state_storage_account_name
  replication_type           = var.state_replication_type
  public_network_access      = var.state_public_network_access
  network_default_action     = var.state_network_default_action
  allowed_ip_ranges          = var.state_allowed_ip_ranges
  log_analytics_workspace_id = var.state_log_analytics_workspace_id
  tags                       = local.tags
}

# Operators keep data-plane access so state can be recovered without the pipeline.
resource "azurerm_role_assignment" "operator_state" {
  for_each = var.operator_object_ids

  scope                = module.state_storage.container_scope
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
  description          = "Platform operator access to Terraform state"
}

# Lets the stack 70 apply identity work with resource-group scope only.
resource "azurerm_resource_group" "secops" {
  for_each = local.secops_enabled ? var.environments : toset([])

  name     = "${var.name_prefix}-${each.key}-secops-rg"
  location = var.location
  tags     = merge(local.tags, { environment = each.key })
}
