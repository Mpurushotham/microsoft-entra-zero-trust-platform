module "lifecycle_workflows" {
  source = "../../modules/entra-lifecycle-workflows"

  name_prefix = var.name_prefix
  environment = var.environment

  workflows = {
    "joiner-pre-hire" = {
      category           = "joiner"
      description        = "Reminds the manager to prepare onboarding a week before the hire date."
      scheduling_enabled = var.lifecycle_scheduling_enabled
      scope_rule         = var.lifecycle_scope_rule
      trigger            = { time_based_attribute = "employeeHireDate", offset_in_days = -7 }
      tasks = [
        { display_name = "Send onboarding reminder to manager", task_definition_id = local.lifecycle_tasks.onboarding_reminder },
      ]
    }
    "joiner-day-one" = {
      category           = "joiner"
      description        = "Enables the account, issues a one-time Temporary Access Pass to the manager for passkey registration and adds onboarding groups."
      scheduling_enabled = var.lifecycle_scheduling_enabled
      scope_rule         = var.lifecycle_scope_rule
      trigger            = { time_based_attribute = "employeeHireDate", offset_in_days = 0 }
      tasks = [
        { display_name = "Enable user account", task_definition_id = local.lifecycle_tasks.enable_account },
        {
          display_name       = "Generate TAP and send to manager"
          task_definition_id = local.lifecycle_tasks.generate_tap
          arguments = {
            tapLifetimeMinutes = "480"
            tapIsUsableOnce    = "true"
          }
        },
        {
          display_name       = "Add user to onboarding groups"
          task_definition_id = local.lifecycle_tasks.add_to_groups
          arguments          = { groupID = local.group_ids["users-new-hires"] }
        },
        { display_name = "Send welcome email", task_definition_id = local.lifecycle_tasks.send_welcome_email },
      ]
    }
    "mover-job-change" = {
      category           = "mover"
      description        = "Notifies the manager to review access when department or job title changes."
      scheduling_enabled = var.lifecycle_scheduling_enabled
      scope_rule         = var.lifecycle_scope_rule
      trigger            = { changed_attributes = ["department", "jobTitle"] }
      tasks = [
        { display_name = "Notify manager of user move", task_definition_id = local.lifecycle_tasks.notify_manager_of_move },
      ]
    }
    "leaver-last-day" = {
      category           = "leaver"
      description        = "Disables sign-in and removes access on the last working day."
      scheduling_enabled = var.lifecycle_scheduling_enabled
      scope_rule         = var.lifecycle_scope_rule
      trigger            = { time_based_attribute = "employeeLeaveDateTime", offset_in_days = 0 }
      tasks = [
        { display_name = "Disable user account", task_definition_id = local.lifecycle_tasks.disable_account },
        { display_name = "Revoke all refresh tokens", task_definition_id = local.lifecycle_tasks.revoke_refresh_tokens, continue_on_error = true },
        { display_name = "Remove all access package assignments", task_definition_id = local.lifecycle_tasks.remove_all_access_packages, continue_on_error = true },
        { display_name = "Remove user from all groups", task_definition_id = local.lifecycle_tasks.remove_from_all_groups, continue_on_error = true },
        { display_name = "Remove user from all Teams", task_definition_id = local.lifecycle_tasks.remove_from_all_teams, continue_on_error = true },
        { display_name = "Send email to manager on last day", task_definition_id = local.lifecycle_tasks.send_email_on_last_day, continue_on_error = true },
      ]
    }
    "leaver-post-offboarding" = {
      category           = "leaver"
      description        = "Removes licenses and deletes the account after the retention window."
      scheduling_enabled = var.lifecycle_scheduling_enabled
      scope_rule         = var.lifecycle_scope_rule
      trigger            = { time_based_attribute = "employeeLeaveDateTime", offset_in_days = var.leaver_delete_after_days }
      tasks = [
        { display_name = "Remove all licenses", task_definition_id = local.lifecycle_tasks.remove_all_licenses },
        { display_name = "Delete user account", task_definition_id = local.lifecycle_tasks.delete_account },
      ]
    }
  }
}
