resource "azuread_conditional_access_policy" "this" {
  for_each = var.policies

  display_name = each.value.display_name
  state        = coalesce(each.value.state, var.default_state)

  conditions {
    client_app_types                     = each.value.client_app_types
    authentication_flow_transfer_methods = each.value.authentication_flow_transfer_methods
    sign_in_risk_levels                  = each.value.sign_in_risk_levels
    user_risk_levels                     = each.value.user_risk_levels
    insider_risk_levels                  = each.value.insider_risk_levels
    service_principal_risk_levels        = each.value.service_principal_risk_levels

    users {
      included_users  = each.value.included_users
      excluded_users  = each.value.excluded_users
      included_groups = each.value.included_groups
      excluded_groups = distinct(concat(each.value.excluded_groups, var.emergency_access_group_ids))
      included_roles  = each.value.included_roles
      excluded_roles  = each.value.excluded_roles

      dynamic "included_guests_or_external_users" {
        for_each = each.value.included_guests_or_external_users == null ? [] : [each.value.included_guests_or_external_users]
        content {
          guest_or_external_user_types = included_guests_or_external_users.value.types
          external_tenants {
            membership_kind = included_guests_or_external_users.value.external_tenant_kind
            members         = included_guests_or_external_users.value.external_tenant_members
          }
        }
      }

      dynamic "excluded_guests_or_external_users" {
        for_each = each.value.excluded_guests_or_external_users == null ? [] : [each.value.excluded_guests_or_external_users]
        content {
          guest_or_external_user_types = excluded_guests_or_external_users.value.types
          external_tenants {
            membership_kind = excluded_guests_or_external_users.value.external_tenant_kind
            members         = excluded_guests_or_external_users.value.external_tenant_members
          }
        }
      }
    }

    applications {
      included_applications = each.value.included_applications
      excluded_applications = each.value.excluded_applications
      included_user_actions = each.value.included_user_actions
    }

    dynamic "client_applications" {
      for_each = each.value.included_service_principals == null ? [] : [1]
      content {
        included_service_principals = each.value.included_service_principals
        excluded_service_principals = each.value.excluded_service_principals
      }
    }

    dynamic "devices" {
      for_each = each.value.device_filter == null ? [] : [each.value.device_filter]
      content {
        filter {
          mode = devices.value.mode
          rule = devices.value.rule
        }
      }
    }

    dynamic "locations" {
      for_each = each.value.included_locations == null ? [] : [1]
      content {
        included_locations = each.value.included_locations
        excluded_locations = each.value.excluded_locations
      }
    }

    dynamic "platforms" {
      for_each = each.value.included_platforms == null ? [] : [1]
      content {
        included_platforms = each.value.included_platforms
        excluded_platforms = each.value.excluded_platforms
      }
    }
  }

  dynamic "grant_controls" {
    for_each = each.value.grant == null ? [] : [each.value.grant]
    content {
      operator                          = grant_controls.value.operator
      built_in_controls                 = grant_controls.value.built_in_controls
      authentication_strength_policy_id = grant_controls.value.authentication_strength_policy_id
      terms_of_use                      = grant_controls.value.terms_of_use
    }
  }

  dynamic "session_controls" {
    for_each = each.value.session == null ? [] : [each.value.session]
    content {
      application_enforced_restrictions_enabled = session_controls.value.application_enforced_restrictions_enabled
      cloud_app_security_policy                 = session_controls.value.cloud_app_security_policy
      disable_resilience_defaults               = session_controls.value.disable_resilience_defaults
      persistent_browser_mode                   = session_controls.value.persistent_browser_mode
      sign_in_frequency                         = session_controls.value.sign_in_frequency
      sign_in_frequency_period                  = session_controls.value.sign_in_frequency_period
      sign_in_frequency_interval                = session_controls.value.sign_in_frequency_interval
      sign_in_frequency_authentication_type     = session_controls.value.sign_in_frequency_authentication_type
    }
  }
}
