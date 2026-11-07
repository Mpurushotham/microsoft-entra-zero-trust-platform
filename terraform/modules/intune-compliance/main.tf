locals {
  display_prefix = "${var.name_prefix}-${var.environment}"

  # Floors follow the currently serviced releases; raise them as releases fall out of support.
  os_minimum_versions = merge({
    windows               = "10.0.26100.0"
    macos                 = "14.0"
    ios                   = "17.0"
    android_fully_managed = "13.0"
    android_work_profile  = "12.0"
  }, var.os_minimum_versions)

  policies = {
    for p in var.platforms : p => jsondecode(templatefile("${path.module}/templates/${p}.json.tftpl", {
      display_name       = "${local.display_prefix}-compliance-${replace(p, "_", "-")}"
      os_minimum_version = local.os_minimum_versions[p]
      role_scope_tag_ids = var.role_scope_tag_ids
      grace_period_hours = var.noncompliance_grace_period_hours
      threat_enabled     = var.device_threat_protection.enabled
      threat_level       = var.device_threat_protection.level
    }))
  }

  assignments = {
    for k, a in var.assignments : k => concat(
      [for g in a.include_group_ids : { target = { "@odata.type" = "#microsoft.graph.groupAssignmentTarget", groupId = g } }],
      [for g in a.exclude_group_ids : { target = { "@odata.type" = "#microsoft.graph.exclusionGroupAssignmentTarget", groupId = g } }],
    ) if contains(keys(local.policies), k)
  }
}

# beta: roleScopeTagIds and several health-attestation properties are beta-only.
resource "msgraph_resource" "policy" {
  for_each = local.policies

  url         = "deviceManagement/deviceCompliancePolicies"
  api_version = "beta"
  body        = each.value

  response_export_values = {
    id           = "id"
    display_name = "displayName"
  }
}

resource "msgraph_resource_action" "assign" {
  for_each = local.assignments

  resource_url = msgraph_resource.policy[each.key].resource_url
  action       = "assign"
  method       = "POST"
  api_version  = "beta"
  body         = { assignments = each.value }
}
