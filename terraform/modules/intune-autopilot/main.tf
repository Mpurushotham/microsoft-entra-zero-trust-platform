locals {
  display_prefix = "${var.name_prefix}-${var.environment}"

  profiles = {
    for k, p in var.deployment_profiles : k => jsondecode(templatefile("${path.module}/templates/deployment-profile.json.tftpl", {
      display_name          = "${local.display_prefix}-autopilot-${replace(k, "_", "-")}"
      mode                  = p.mode
      allow_preprovisioning = p.allow_preprovisioning
      device_name_template  = p.device_name_template
      locale                = p.locale
      user_type             = p.mode == "self_deploying" ? "standard" : p.user_type
      role_scope_tag_ids    = var.role_scope_tag_ids
    }))
  }

  profile_assignments = merge([
    for k, p in var.deployment_profiles : merge(
      { for g in p.include_group_ids : "${k}/include/${g}" => { profile = k, group_id = g, odata_type = "#microsoft.graph.groupAssignmentTarget" } },
      { for g in p.exclude_group_ids : "${k}/exclude/${g}" => { profile = k, group_id = g, odata_type = "#microsoft.graph.exclusionGroupAssignmentTarget" } },
    )
  ]...)

  esp_blocking_app_ids = concat(
    var.enrollment_status_page.blocking_app_ids,
    [for k, a in var.required_store_apps : msgraph_resource.store_app[k].id if a.block_esp],
  )
}

# beta: windowsAutopilotDeploymentProfiles is not available on v1.0.
resource "msgraph_resource" "deployment_profile" {
  for_each = local.profiles

  url         = "deviceManagement/windowsAutopilotDeploymentProfiles"
  api_version = "beta"
  body        = each.value

  response_export_values = {
    id = "id"
  }
}

resource "msgraph_resource" "deployment_profile_assignment" {
  for_each = local.profile_assignments

  url         = "${msgraph_resource.deployment_profile[each.value.profile].resource_url}/assignments"
  api_version = "beta"
  body = {
    target = {
      "@odata.type" = each.value.odata_type
      groupId       = each.value.group_id
    }
  }
}

# beta: winGetApp and the required-app assignment settings it uses.
resource "msgraph_resource" "store_app" {
  for_each = var.required_store_apps

  url         = "deviceAppManagement/mobileApps"
  api_version = "beta"
  body = {
    "@odata.type"     = "#microsoft.graph.winGetApp"
    displayName       = each.value.display_name
    description       = "${each.value.display_name} from the Microsoft Store, required during Autopilot provisioning."
    publisher         = each.value.publisher
    packageIdentifier = each.value.package_identifier
    roleScopeTagIds   = var.role_scope_tag_ids
    installExperience = {
      "@odata.type" = "#microsoft.graph.winGetAppInstallExperience"
      runAsAccount  = each.value.run_as_account
    }
  }

  response_export_values = {
    id = "id"
  }
}

resource "msgraph_resource_action" "store_app_assign" {
  for_each = length(var.required_app_group_ids) > 0 ? var.required_store_apps : {}

  resource_url = msgraph_resource.store_app[each.key].resource_url
  action       = "assign"
  method       = "POST"
  api_version  = "beta"
  body = {
    mobileAppAssignments = [for g in var.required_app_group_ids : {
      "@odata.type" = "#microsoft.graph.mobileAppAssignment"
      intent        = "required"
      target = {
        "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
        groupId       = g
      }
      settings = {
        "@odata.type" = "#microsoft.graph.winGetAppAssignmentSettings"
        notifications = "hideAll"
      }
    }]
  }
}

# beta: selectedMobileAppIds, installQualityUpdates and roleScopeTagIds are beta-only on the ESP.
resource "msgraph_resource" "enrollment_status_page" {
  url         = "deviceManagement/deviceEnrollmentConfigurations"
  api_version = "beta"
  body = jsondecode(templatefile("${path.module}/templates/enrollment-status-page.json.tftpl", {
    display_name         = "${local.display_prefix}-autopilot-esp"
    role_scope_tag_ids   = var.role_scope_tag_ids
    priority             = var.enrollment_status_page.priority
    timeout_minutes      = var.enrollment_status_page.timeout_minutes
    blocking_app_ids     = local.esp_blocking_app_ids
    allow_reset          = var.enrollment_status_page.allow_reset_on_failure
    allow_use            = var.enrollment_status_page.allow_use_on_failure
    install_quality      = var.enrollment_status_page.install_quality_updates
    custom_error_message = var.enrollment_status_page.custom_error_message
  }))

  response_export_values = {
    id = "id"
  }
}

resource "msgraph_resource_action" "enrollment_status_page_assign" {
  resource_url = msgraph_resource.enrollment_status_page.resource_url
  action       = "assign"
  method       = "POST"
  api_version  = "beta"
  body = {
    enrollmentConfigurationAssignments = [for g in var.enrollment_status_page.include_group_ids : {
      target = { "@odata.type" = "#microsoft.graph.groupAssignmentTarget", groupId = g }
    }]
  }
}

# beta: androidDeviceOwnerEnrollmentProfiles is not available on v1.0.
resource "msgraph_resource" "android_fully_managed" {
  count = var.android_zero_touch.enabled ? 1 : 0

  url         = "deviceManagement/androidDeviceOwnerEnrollmentProfiles"
  api_version = "beta"
  body = {
    displayName         = "${local.display_prefix}-android-fully-managed"
    description         = "Corporate-owned fully managed Android Enterprise devices provisioned through the zero-touch portal."
    enrollmentMode      = "corporateOwnedFullyManaged"
    enrollmentTokenType = "default"
    roleScopeTagIds     = var.role_scope_tag_ids
  }

  response_export_values = {
    id = "id"
  }
}

# beta: depOnboardingSettings (Apple ADE) is not available on v1.0.
resource "msgraph_resource" "apple_ade_profile" {
  count = var.apple_ade.dep_onboarding_setting_id == null ? 0 : 1

  url         = "deviceManagement/depOnboardingSettings/${var.apple_ade.dep_onboarding_setting_id}/enrollmentProfiles"
  api_version = "beta"
  body = jsondecode(templatefile("${path.module}/templates/apple-ade-profile.json.tftpl", {
    display_name         = "${local.display_prefix}-ade-ios-user-affinity"
    support_phone_number = var.apple_ade.support_phone_number
    support_department   = var.apple_ade.support_department
  }))

  response_export_values = {
    id = "id"
  }
}
