output "locations" {
  description = "Object ID (the value Conditional Access expects) and display name per location key."
  value = {
    for k, l in merge(azuread_named_location.ip, azuread_named_location.country) : k => {
      object_id    = l.object_id
      display_name = l.display_name
    }
  }
}
