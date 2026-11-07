locals {
  apps_with_claims = { for key, app in local.apps : key => app if length(app.claims_schema) > 0 }
}

resource "azuread_claims_mapping_policy" "app" {
  for_each = local.apps_with_claims

  display_name = "${var.name_prefix}-${var.environment}-${each.value.display_name}-claims"
  definition = [
    jsonencode({
      ClaimsMappingPolicy = {
        Version              = 1
        IncludeBasicClaimSet = "true"
        ClaimsSchema         = [for claim in each.value.claims_schema : { for k, v in claim : k => v if v != null }]
      }
    })
  ]
}

resource "azuread_service_principal_claims_mapping_policy_assignment" "app" {
  for_each = local.apps_with_claims

  claims_mapping_policy_id = azuread_claims_mapping_policy.app[each.key].id
  service_principal_id     = azuread_service_principal.app[each.key].id
}
