data "azuread_group" "this" {
  for_each = local.lookup_groups

  display_name     = "${local.name}-${each.key}"
  security_enabled = true
}

data "azuread_user" "eligible" {
  for_each = local.eligible_members

  user_principal_name = each.value.upn
}
