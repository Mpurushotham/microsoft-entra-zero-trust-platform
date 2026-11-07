resource "azuread_access_package_catalog" "this" {
  for_each = var.catalogs

  display_name       = "${var.name_prefix}-${var.environment}-catalog-${each.key}"
  description        = each.value.description
  externally_visible = each.value.externally_visible
  published          = true
}

locals {
  # Groups granted by a package are added to its catalog automatically.
  catalog_resources = merge(
    [
      for ck, c in var.catalogs : {
        for g in distinct(concat(c.resource_group_ids, flatten([for p in values(var.access_packages) : p.group_ids if p.catalog_key == ck]))) :
        "${ck}/${g}" => { catalog_key = ck, group_id = g }
      }
    ]...
  )

  package_resources = merge(
    [
      for pk, p in var.access_packages : {
        for g in p.group_ids : "${pk}/${g}" => {
          package_key = pk
          catalog_key = p.catalog_key
          group_id    = g
          access_type = p.access_type
        }
      }
    ]...
  )
}

resource "azuread_access_package_resource_catalog_association" "group" {
  for_each = local.catalog_resources

  catalog_id             = azuread_access_package_catalog.this[each.value.catalog_key].id
  resource_origin_id     = each.value.group_id
  resource_origin_system = "AadGroup"
}
