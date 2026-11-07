# azuread has no resource for directory-role PIM settings.
data "msgraph_resource" "role_policy_assignment" {
  for_each = var.directory_role_policies

  url = "policies/roleManagementPolicyAssignments"
  query_parameters = {
    "$filter" = ["scopeId eq '/' and scopeType eq 'DirectoryRole' and roleDefinitionId eq '${each.value.role_template_id}'"]
  }
  response_export_values = {
    policy_id = "value[0].policyId"
  }
}

locals {
  rule_target = {
    end_user_assignment = {
      caller              = "EndUser"
      operations          = ["All"]
      level               = "Assignment"
      inheritableSettings = []
      enforcedSettings    = []
    }
    admin_eligibility = {
      caller              = "Admin"
      operations          = ["All"]
      level               = "Eligibility"
      inheritableSettings = []
      enforcedSettings    = []
    }
  }

  directory_role_rules = merge([
    for key, p in var.directory_role_policies : {
      "${key}/Expiration_EndUser_Assignment" = {
        policy_key = key
        rule_id    = "Expiration_EndUser_Assignment"
        body = {
          "@odata.type"        = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
          id                   = "Expiration_EndUser_Assignment"
          isExpirationRequired = true
          maximumDuration      = p.activation_maximum_duration
          target               = local.rule_target.end_user_assignment
        }
      }
      "${key}/Enablement_EndUser_Assignment" = {
        policy_key = key
        rule_id    = "Enablement_EndUser_Assignment"
        body = {
          "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule"
          id            = "Enablement_EndUser_Assignment"
          enabledRules = compact([
            p.require_multifactor_on_activation ? "MultiFactorAuthentication" : "",
            p.require_justification ? "Justification" : "",
            p.require_ticket_info ? "Ticketing" : "",
          ])
          target = local.rule_target.end_user_assignment
        }
      }
      "${key}/Approval_EndUser_Assignment" = {
        policy_key = key
        rule_id    = "Approval_EndUser_Assignment"
        body = {
          "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyApprovalRule"
          id            = "Approval_EndUser_Assignment"
          setting = {
            isApprovalRequired               = p.require_approval
            isApprovalRequiredForExtension   = false
            isRequestorJustificationRequired = true
            approvalMode                     = "SingleStage"
            approvalStages = [{
              approvalStageTimeOutInDays      = 1
              isApproverJustificationRequired = true
              escalationTimeInMinutes         = 0
              isEscalationEnabled             = false
              primaryApprovers = [for g in p.approver_group_object_ids : {
                "@odata.type" = "#microsoft.graph.groupMembers"
                groupId       = g
              }]
              escalationApprovers = []
            }]
          }
          target = local.rule_target.end_user_assignment
        }
      }
      "${key}/Expiration_Admin_Eligibility" = {
        policy_key = key
        rule_id    = "Expiration_Admin_Eligibility"
        body = {
          "@odata.type"        = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
          id                   = "Expiration_Admin_Eligibility"
          isExpirationRequired = true
          maximumDuration      = p.eligible_maximum_duration
          target               = local.rule_target.admin_eligibility
        }
      }
    }
  ]...)
}

resource "msgraph_update_resource" "directory_role_rule" {
  for_each = local.directory_role_rules

  url  = "policies/roleManagementPolicies/${data.msgraph_resource.role_policy_assignment[each.value.policy_key].output.policy_id}/rules/${each.value.rule_id}"
  body = each.value.body
}
