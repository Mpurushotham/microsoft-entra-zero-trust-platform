locals {
  display_prefix = "${var.name_prefix}-${var.environment}"

  restriction_targets = [for g in var.restriction_group_ids : {
    target = { "@odata.type" = "#microsoft.graph.groupAssignmentTarget", groupId = g }
  }]

  platform_restrictions = {
    for k, r in var.platform_restrictions : k => jsondecode(templatefile("${path.module}/templates/platform-restriction.json.tftpl", {
      display_name       = "${local.display_prefix}-enroll-restrict-${lower(k)}"
      platform_type      = k
      role_scope_tag_ids = var.role_scope_tag_ids
      priority           = r.priority
      platform_blocked   = r.platform_blocked
      personal_blocked   = r.personal_devices_blocked
      os_minimum_version = r.os_minimum_version
      os_maximum_version = r.os_maximum_version
    }))
  }
}

# beta: per-platform restriction type exists only on beta.
resource "msgraph_resource" "platform_restriction" {
  for_each = local.platform_restrictions

  url         = "deviceManagement/deviceEnrollmentConfigurations"
  api_version = "beta"
  body        = each.value

  response_export_values = {
    id = "id"
  }
}

resource "msgraph_resource_action" "platform_restriction_assign" {
  for_each = local.platform_restrictions

  resource_url = msgraph_resource.platform_restriction[each.key].resource_url
  action       = "assign"
  method       = "POST"
  api_version  = "beta"
  body         = { enrollmentConfigurationAssignments = local.restriction_targets }
}

resource "msgraph_resource" "device_limit" {
  url         = "deviceManagement/deviceEnrollmentConfigurations"
  api_version = "beta"
  body = {
    "@odata.type"   = "#microsoft.graph.deviceEnrollmentLimitConfiguration"
    displayName     = "${local.display_prefix}-enroll-device-limit"
    description     = "Caps the number of devices a user can enroll."
    priority        = var.device_limit_priority
    limit           = var.device_limit
    roleScopeTagIds = var.role_scope_tag_ids
  }

  response_export_values = {
    id = "id"
  }
}

resource "msgraph_resource_action" "device_limit_assign" {
  resource_url = msgraph_resource.device_limit.resource_url
  action       = "assign"
  method       = "POST"
  api_version  = "beta"
  body         = { enrollmentConfigurationAssignments = local.restriction_targets }
}

resource "msgraph_resource" "device_category" {
  for_each = var.device_categories

  url         = "deviceManagement/deviceCategories"
  api_version = "beta"
  body = {
    displayName     = each.key
    description     = each.value
    roleScopeTagIds = var.role_scope_tag_ids
  }

  response_export_values = {
    id = "id"
  }
}
