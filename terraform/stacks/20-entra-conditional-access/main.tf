module "conditional_access" {
  source = "../../modules/entra-conditional-access"

  default_state              = var.ca_state
  emergency_access_group_ids = [data.azuread_group.emergency_access.object_id]
  policies                   = local.policies
  token_protection_policies  = local.token_protection_policies
}
