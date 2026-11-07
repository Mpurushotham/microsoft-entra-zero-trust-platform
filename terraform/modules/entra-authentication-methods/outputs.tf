output "authentication_strengths" {
  description = "ID (prefixed form expected by azuread_conditional_access_policy) and display name per key."
  value = {
    for k, s in azuread_authentication_strength_policy.this : k => {
      id           = s.id
      object_id    = s.object_id
      display_name = s.display_name
    }
  }
}
