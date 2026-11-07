module "staged_rollout" {
  source = "../../modules/hybrid-staged-rollout"

  name_prefix     = var.name_prefix
  environment     = var.environment
  waves           = var.migration_waves
  enabled_waves   = var.enabled_waves
  staged_features = var.staged_features
  rollout_enabled = var.staged_rollout_enabled
  group_owners    = var.wave_group_owners
}

data "azuread_group" "assignment" {
  for_each = local.external_group_names

  display_name     = each.key
  security_enabled = true
}

module "app_migration" {
  source = "../../modules/hybrid-app-migration"

  name_prefix = var.name_prefix
  environment = var.environment

  applications = {
    for key, app in var.migrated_applications : key => {
      display_name                 = app.display_name
      protocol                     = app.protocol
      adfs_relying_party           = app.adfs_relying_party
      template_id                  = app.template_id
      identifier_uris              = app.identifier_uris
      redirect_uris                = app.redirect_uris
      homepage_url                 = app.homepage_url
      logout_url                   = app.logout_url
      login_url                    = app.login_url
      relay_state                  = app.relay_state
      notification_email_addresses = app.notification_email_addresses
      app_role_assignment_required = app.app_role_assignment_required
      group_membership_claims      = app.group_membership_claims
      hide_from_my_apps            = app.hide_from_my_apps
      owners                       = tolist(var.wave_group_owners)
      signing_certificate_end_date = app.signing_certificate_end_date
      claims_schema                = app.claims_schema
      # Labels are static so for_each keys are known at plan time.
      assignment_groups = merge(
        { for wave in app.assign_to_waves : "wave-${wave}" => module.staged_rollout.wave_groups[wave].object_id },
        { for name in app.assignment_group_display_names : "group-${name}" => data.azuread_group.assignment[name].object_id },
      )
    }
  }
}
