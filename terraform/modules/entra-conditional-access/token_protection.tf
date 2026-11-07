resource "msgraph_resource" "token_protection" {
  for_each = var.token_protection_policies

  url         = "identity/conditionalAccess/policies"
  api_version = "beta"

  body = {
    displayName = each.value.display_name
    state       = coalesce(each.value.state, var.default_state)
    conditions = {
      clientAppTypes = ["mobileAppsAndDesktopClients"]
      users = {
        includeUsers  = each.value.included_users
        includeGroups = each.value.included_groups
        includeRoles  = each.value.included_roles
        excludeGroups = distinct(concat(each.value.excluded_groups, var.emergency_access_group_ids))
      }
      applications = {
        includeApplications = each.value.included_applications
      }
      platforms = {
        includePlatforms = each.value.included_platforms
      }
    }
    sessionControls = {
      secureSignInSession = {
        isEnabled = true
      }
    }
  }

  response_export_values = {
    id = "id"
  }
}
