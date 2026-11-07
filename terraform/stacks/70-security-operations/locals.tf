locals {
  resource_group_name = coalesce(var.resource_group_name, "${var.name_prefix}-${var.environment}-secops-rg")

  tags = merge(var.tags, {
    workload    = "entra-zero-trust-platform"
    stack       = "70-security-operations"
    environment = var.environment
    managed-by  = "terraform"
  })

  # Conditional Access changes made by these pipeline identities are expected and do not alert.
  trusted_automation_names = [for e in ["dev", "prod"] : "${var.name_prefix}-${e}-github-apply"]
}
