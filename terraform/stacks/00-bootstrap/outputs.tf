output "tfstate_resource_group" {
  description = "GitHub repository variable TFSTATE_RG."
  value       = azurerm_resource_group.state.name
}

output "tfstate_storage_account" {
  description = "GitHub repository variable TFSTATE_SA."
  value       = module.state_storage.storage_account_name
}

output "tfstate_container" {
  value = module.state_storage.container_name
}

output "github_plan_client_ids" {
  description = "Repository secrets AZURE_PLAN_CLIENT_ID_DEV / AZURE_PLAN_CLIENT_ID_PROD."
  value       = { for env, m in module.github_plan : env => m.client_id }
}

output "github_apply_client_ids" {
  description = "Environment secret AZURE_CLIENT_ID in the matching GitHub environment."
  value       = { for env, m in module.github_apply : env => m.client_id }
}

output "tenant_id" {
  description = "Repository secret AZURE_TENANT_ID."
  value       = data.azurerm_subscription.current.tenant_id
}

output "subscription_id" {
  description = "Repository secret AZURE_SUBSCRIPTION_ID."
  value       = data.azurerm_subscription.current.subscription_id
}

output "secops_resource_groups" {
  value = { for env, rg in azurerm_resource_group.secops : env => rg.name }
}

output "graph_permissions" {
  description = "Microsoft Graph application permissions granted (admin consented) per identity type."
  value = {
    plan  = sort(tolist(local.plan_graph_roles))
    apply = sort(tolist(local.apply_graph_roles))
  }
}
