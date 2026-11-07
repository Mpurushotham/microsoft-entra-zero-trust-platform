output "policies" {
  description = "Object ID, display name and state per policy key."
  value = merge(
    {
      for k, p in azuread_conditional_access_policy.this : k => {
        object_id    = p.object_id
        display_name = p.display_name
        state        = p.state
      }
    },
    {
      for k, p in msgraph_resource.token_protection : k => {
        object_id    = p.id
        display_name = var.token_protection_policies[k].display_name
        state        = coalesce(var.token_protection_policies[k].state, var.default_state)
      }
    }
  )
}
