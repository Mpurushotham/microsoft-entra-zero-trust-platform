resource "azuread_group_role_management_policy" "member" {
  for_each = var.group_policies

  group_id = each.value.group_object_id
  role_id  = "member"

  activation_rules {
    maximum_duration                   = each.value.activation_maximum_duration
    require_approval                   = each.value.require_approval
    require_justification              = each.value.require_justification
    require_multifactor_authentication = each.value.require_multifactor_on_activation
    require_ticket_info                = each.value.require_ticket_info

    dynamic "approval_stage" {
      for_each = each.value.require_approval ? [1] : []
      content {
        dynamic "primary_approver" {
          for_each = toset(each.value.approver_group_object_ids)
          content {
            object_id = primary_approver.value
            type      = "groupMembers"
          }
        }
      }
    }
  }

  eligible_assignment_rules {
    expiration_required = true
    expire_after        = each.value.eligible_expire_after
  }

  active_assignment_rules {
    expiration_required                = true
    expire_after                       = each.value.active_expire_after
    require_justification              = true
    require_multifactor_authentication = true
  }

  dynamic "notification_rules" {
    for_each = length(each.value.notification_recipients) > 0 ? [1] : []
    content {
      eligible_activations {
        admin_notifications {
          notification_level    = "All"
          default_recipients    = true
          additional_recipients = each.value.notification_recipients
        }
      }
    }
  }
}

resource "azuread_privileged_access_group_eligibility_schedule" "member" {
  for_each = var.group_eligible_members

  group_id        = each.value.group_object_id
  principal_id    = each.value.principal_object_id
  assignment_type = "member"
  duration        = each.value.duration
  justification   = each.value.justification

  depends_on = [azuread_group_role_management_policy.member]
}
