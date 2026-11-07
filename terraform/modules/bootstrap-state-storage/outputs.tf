output "storage_account_id" {
  value = azurerm_storage_account.state.id
}

output "storage_account_name" {
  description = "Value for the TFSTATE_SA GitHub variable."
  value       = azurerm_storage_account.state.name
}

output "container_name" {
  value = azurerm_storage_container.state.name
}

output "container_scope" {
  description = "ARM scope of the state container, for data-plane RBAC."
  value       = "${azurerm_storage_account.state.id}/blobServices/default/containers/${azurerm_storage_container.state.name}"
}
