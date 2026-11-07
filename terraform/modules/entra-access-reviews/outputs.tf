output "review_definition_ids" {
  value = merge(
    { for k, r in msgraph_resource.group_membership : k => r.id },
    { for r in msgraph_resource.inactive_guests : "inactive-guests-m365-groups" => r.id },
  )
}
