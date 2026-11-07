module "pim" {
  source = "../../modules/entra-pim"

  role_eligibilities = {
    for group_key, role in local.tier0_groups : group_key => {
      principal_object_id = local.group_ids[group_key]
      role_template_id    = role
    }
  }

  role_assignments = {
    for group_key, role in local.tier1_groups : group_key => {
      principal_object_id = local.group_ids[group_key]
      role_template_id    = role
    }
  }

  group_policies = {
    for group_key in local.jit_groups : group_key => {
      group_object_id             = local.group_ids[group_key]
      activation_maximum_duration = local.hours[var.tier1_activation_hours]
      require_justification       = true
      require_ticket_info         = var.environment == "prod"
      notification_recipients     = var.pim_notification_recipients
    }
  }

  group_eligible_members = {
    for k, m in local.eligible_members : k => {
      group_object_id     = local.group_ids[m.group_key]
      principal_object_id = data.azuread_user.eligible[k].object_id
    }
  }

  directory_role_policies = {
    for group_key, role in local.tier0_groups : group_key => {
      role_template_id            = role
      activation_maximum_duration = local.hours[var.tier0_activation_hours]
      require_ticket_info         = var.environment == "prod"
      require_approval            = true
      approver_group_object_ids   = [local.approvers]
      eligible_maximum_duration   = "P365D"
    }
  }
}
