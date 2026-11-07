resource "msgraph_resource" "attribute_set" {
  for_each = var.attribute_sets

  url = "directory/attributeSets"
  body = {
    id                  = each.key
    description         = each.value.description
    maxAttributesPerSet = each.value.max_attributes_per_set
  }

  lifecycle {
    # Entra ID cannot delete attribute sets; a destroy would fail half-way.
    prevent_destroy = true
  }
}

locals {
  definitions = merge([
    for set_name, s in var.attribute_sets : {
      for attr_name, a in s.attributes : "${set_name}_${attr_name}" => merge(a, {
        set_name  = set_name
        attr_name = attr_name
      })
    }
  ]...)
}

resource "msgraph_resource" "definition" {
  for_each = local.definitions

  url = "directory/customSecurityAttributeDefinitions"
  body = {
    attributeSet            = msgraph_resource.attribute_set[each.value.set_name].id
    name                    = each.value.attr_name
    description             = each.value.description
    type                    = each.value.type
    isCollection            = each.value.is_collection
    isSearchable            = each.value.is_searchable
    usePreDefinedValuesOnly = each.value.use_pre_defined_values_only
    status                  = "Available"
  }

  lifecycle {
    # Definitions cannot be deleted, only set to status "Deprecated".
    prevent_destroy = true
  }
}
