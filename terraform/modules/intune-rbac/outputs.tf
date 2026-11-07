output "scope_tag_ids" {
  description = "Scope tag IDs keyed by short name, for use in role_scope_tag_ids of other modules."
  value       = local.scope_tag_ids
}

output "role_assignment_ids" {
  value = { for k, a in msgraph_resource.role_assignment : k => a.id }
}
