resource "azuread_authentication_strength_policy" "this" {
  for_each = var.authentication_strengths

  display_name         = "${var.name_prefix}-${var.environment}-as-${each.key}"
  description          = each.value.description
  allowed_combinations = each.value.allowed_combinations
}
