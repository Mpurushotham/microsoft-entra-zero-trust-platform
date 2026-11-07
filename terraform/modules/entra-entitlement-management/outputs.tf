output "catalog_ids" {
  value = { for k, c in azuread_access_package_catalog.this : k => c.id }
}

output "access_packages" {
  description = "ID and display name per access package; IDs are consumed by lifecycle workflow tasks."
  value = {
    for k, p in azuread_access_package.this : k => {
      id           = p.id
      display_name = p.display_name
    }
  }
}
