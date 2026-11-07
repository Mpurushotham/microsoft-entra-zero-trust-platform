output "client_id" {
  description = "Value for the AZURE_CLIENT_ID GitHub secret."
  value       = azuread_application_registration.this.client_id
}

output "application_object_id" {
  value = azuread_application_registration.this.object_id
}

output "service_principal_object_id" {
  value = azuread_service_principal.this.object_id
}

output "federated_subjects" {
  value = sort([for c in azuread_application_federated_identity_credential.github : c.subject])
}

output "graph_app_roles" {
  value = sort(tolist(var.graph_app_roles))
}
