output "definition_ids" {
  description = "Definition IDs in <set>_<attribute> form, as used in user customSecurityAttributes and CA filters."
  value       = { for k, d in msgraph_resource.definition : k => d.id }
}
