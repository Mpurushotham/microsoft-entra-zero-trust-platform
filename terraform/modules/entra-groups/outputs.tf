output "groups" {
  description = "Object ID and display name per group key."
  value = {
    for k, g in azuread_group.this : k => {
      object_id    = g.object_id
      display_name = g.display_name
    }
  }
}

output "object_ids" {
  value = { for k, g in azuread_group.this : k => g.object_id }
}
