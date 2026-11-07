# Staged rollout rejects dynamic and nested groups; membership is batched by Start-StagedRolloutWave.ps1.
resource "azuread_group" "wave" {
  for_each = toset(var.waves)

  display_name            = "${var.name_prefix}-${var.environment}-hybrid-wave-${each.key}"
  description             = "Staged rollout ${each.key}: users moved from federated to cloud authentication."
  security_enabled        = true
  mail_enabled            = false
  prevent_duplicate_names = true
  owners                  = length(var.group_owners) > 0 ? var.group_owners : null

  lifecycle {
    ignore_changes = [members]
  }
}
