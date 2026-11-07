output "administrative_units" {
  value = {
    for k, au in azuread_administrative_unit.this : k => {
      object_id    = au.object_id
      display_name = au.display_name
    }
  }
}
