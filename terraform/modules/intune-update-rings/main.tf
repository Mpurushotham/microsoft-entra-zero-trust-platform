locals {
  display_prefix = "${var.name_prefix}-${var.environment}"

  rings = {
    for k, r in var.rings : k => jsondecode(templatefile("${path.module}/templates/update-ring.json.tftpl", merge(r, {
      display_name       = "${local.display_prefix}-wufb-ring-${k}"
      role_scope_tag_ids = var.role_scope_tag_ids
      active_hours_start = "${var.active_hours.start}.0000000"
      active_hours_end   = "${var.active_hours.end}.0000000"
    })))
  }

  feature_profiles = {
    for k, p in var.feature_update_profiles : k => jsondecode(templatefile("${path.module}/templates/feature-update.json.tftpl", {
      display_name           = "${local.display_prefix}-feature-update-${k}"
      feature_update_version = p.feature_update_version
      role_scope_tag_ids     = var.role_scope_tag_ids
    }))
  }
}

# beta: roleScopeTagIds on update rings, and windowsFeatureUpdateProfiles has no v1.0 endpoint.
resource "msgraph_resource" "ring" {
  for_each = local.rings

  url         = "deviceManagement/deviceConfigurations"
  api_version = "beta"
  body        = each.value

  response_export_values = {
    id = "id"
  }
}

resource "msgraph_resource_action" "ring_assign" {
  for_each = var.rings

  resource_url = msgraph_resource.ring[each.key].resource_url
  action       = "assign"
  method       = "POST"
  api_version  = "beta"
  body = {
    assignments = concat(
      [for g in each.value.include_group_ids : { target = { "@odata.type" = "#microsoft.graph.groupAssignmentTarget", groupId = g } }],
      [for g in each.value.exclude_group_ids : { target = { "@odata.type" = "#microsoft.graph.exclusionGroupAssignmentTarget", groupId = g } }],
    )
  }
}

resource "msgraph_resource" "feature_update" {
  for_each = local.feature_profiles

  url         = "deviceManagement/windowsFeatureUpdateProfiles"
  api_version = "beta"
  body        = each.value

  response_export_values = {
    id = "id"
  }
}

resource "msgraph_resource_action" "feature_update_assign" {
  for_each = var.feature_update_profiles

  resource_url = msgraph_resource.feature_update[each.key].resource_url
  action       = "assign"
  method       = "POST"
  api_version  = "beta"
  body = {
    assignments = concat(
      [for g in each.value.include_group_ids : { target = { "@odata.type" = "#microsoft.graph.groupAssignmentTarget", groupId = g } }],
      [for g in each.value.exclude_group_ids : { target = { "@odata.type" = "#microsoft.graph.exclusionGroupAssignmentTarget", groupId = g } }],
    )
  }
}
