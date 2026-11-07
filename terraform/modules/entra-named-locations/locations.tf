resource "azuread_named_location" "ip" {
  for_each = var.ip_locations

  display_name = "${var.name_prefix}-${var.environment}-nl-${each.key}"

  ip {
    ip_ranges = each.value.ip_ranges
    trusted   = each.value.trusted
  }
}

resource "azuread_named_location" "country" {
  for_each = var.country_locations

  display_name = "${var.name_prefix}-${var.environment}-nl-${each.key}"

  country {
    countries_and_regions                 = each.value.countries_and_regions
    include_unknown_countries_and_regions = each.value.include_unknown_countries_and_regions
    country_lookup_method                 = each.value.country_lookup_method
  }
}
