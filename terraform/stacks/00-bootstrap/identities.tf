module "github_plan" {
  source   = "../../modules/bootstrap-github-oidc"
  for_each = var.environments

  display_name      = "${var.name_prefix}-${each.key}-github-plan"
  description       = "Read-only Terraform plan identity for ${each.key} (pull requests and ${var.github_default_branch})."
  github_repository = var.github_repository
  github_subjects   = ["pull_request", "ref:refs/heads/${var.github_default_branch}"]
  graph_app_roles   = local.plan_graph_roles
  owner_object_ids  = var.operator_object_ids

  azure_role_assignments = {
    subscription-reader = {
      scope                = data.azurerm_subscription.current.id
      role_definition_name = "Reader"
    }
    state-reader = {
      scope                = module.state_storage.container_scope
      role_definition_name = "Storage Blob Data Reader"
    }
  }
}

module "github_apply" {
  source   = "../../modules/bootstrap-github-oidc"
  for_each = var.environments

  display_name                = "${var.name_prefix}-${each.key}-github-apply"
  description                 = "Terraform apply identity for ${each.key}; usable only from the protected GitHub environment."
  github_repository           = var.github_repository
  github_subjects             = ["environment:${each.key}"]
  graph_app_roles             = local.apply_graph_roles
  directory_role_template_ids = toset([for r in local.apply_dir_roles : local.role_template_ids[r]])
  owner_object_ids            = var.operator_object_ids

  azure_role_assignments = merge(
    {
      state-contributor = {
        scope                = module.state_storage.container_scope
        role_definition_name = "Storage Blob Data Contributor"
      }
    },
    local.secops_enabled ? {
      secops-log-analytics = {
        scope                = azurerm_resource_group.secops[each.key].id
        role_definition_name = "Log Analytics Contributor"
      }
      secops-sentinel = {
        scope                = azurerm_resource_group.secops[each.key].id
        role_definition_name = "Microsoft Sentinel Contributor"
      }
    } : {}
  )
}
