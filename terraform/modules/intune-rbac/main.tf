locals {
  display_prefix = "${var.name_prefix}-${var.environment}"

  role_definition_ids = {
    for r in data.msgraph_resource.role_definitions.output.roles : r.name => r.id
  }

  scope_tag_ids = { for k, t in msgraph_resource.scope_tag : k => t.id }
}

# beta: roleScopeTags and roleScopeTagIds on role assignments are beta-only.
data "msgraph_resource" "role_definitions" {
  url         = "deviceManagement/roleDefinitions"
  api_version = "beta"

  response_export_values = {
    roles = "value[].{id: id, name: displayName}"
  }
}

resource "msgraph_resource" "scope_tag" {
  for_each = var.scope_tags

  url         = "deviceManagement/roleScopeTags"
  api_version = "beta"
  body = {
    displayName = "${local.display_prefix}-${each.key}"
    description = each.value.description
  }

  response_export_values = {
    id = "id"
  }
}

resource "msgraph_resource_action" "scope_tag_assign" {
  for_each = { for k, t in var.scope_tags : k => t if length(t.device_group_ids) > 0 }

  resource_url = msgraph_resource.scope_tag[each.key].resource_url
  action       = "assign"
  method       = "POST"
  api_version  = "beta"
  body = {
    assignments = [for g in each.value.device_group_ids : {
      "@odata.type" = "#microsoft.graph.roleScopeTagAutoAssignment"
      target = {
        "@odata.type" = "#microsoft.graph.groupAssignmentTarget"
        groupId       = g
      }
    }]
  }
}

resource "msgraph_resource" "role_assignment" {
  for_each = var.role_assignments

  url         = "deviceManagement/roleAssignments"
  api_version = "beta"
  body = {
    "@odata.type"               = "#microsoft.graph.deviceAndAppManagementRoleAssignment"
    displayName                 = "${local.display_prefix}-${each.key}"
    description                 = "Intune role ${each.value.role_display_name} managed as code."
    members                     = each.value.member_group_ids
    scopeType                   = each.value.scope_type
    resourceScopes              = each.value.scope_type == "resourceScope" ? each.value.scope_group_ids : []
    roleScopeTagIds             = length(each.value.scope_tag_keys) > 0 ? [for k in each.value.scope_tag_keys : local.scope_tag_ids[k]] : ["0"]
    "roleDefinition@odata.bind" = "https://graph.microsoft.com/beta/deviceManagement/roleDefinitions('${local.role_definition_ids[each.value.role_display_name]}')"
  }

  response_export_values = {
    id = "id"
  }
}
