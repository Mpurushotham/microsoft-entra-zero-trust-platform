resource "azuread_access_package" "this" {
  for_each = var.access_packages

  catalog_id   = azuread_access_package_catalog.this[each.value.catalog_key].id
  display_name = "${var.name_prefix}-${var.environment}-ap-${each.key}"
  description  = each.value.description
  hidden       = each.value.hidden
}

resource "azuread_access_package_resource_package_association" "group" {
  for_each = local.package_resources

  access_package_id               = azuread_access_package.this[each.value.package_key].id
  catalog_resource_association_id = azuread_access_package_resource_catalog_association.group["${each.value.catalog_key}/${each.value.group_id}"].id
  access_type                     = each.value.access_type
}

resource "azuread_access_package_assignment_policy" "this" {
  for_each = var.access_packages

  access_package_id = azuread_access_package.this[each.key].id
  display_name      = "${var.name_prefix}-${var.environment}-ap-${each.key}-policy"
  description       = "Default request policy for ${each.key}"
  duration_in_days  = each.value.policy.duration_in_days
  extension_enabled = each.value.policy.extension_enabled

  requestor_settings {
    requests_accepted = true
    scope_type        = each.value.policy.requestor_scope_type

    dynamic "requestor" {
      for_each = toset(each.value.policy.requestor_group_ids)
      content {
        subject_type = "groupMembers"
        object_id    = requestor.value
      }
    }
  }

  approval_settings {
    approval_required                = each.value.policy.approval_required
    requestor_justification_required = each.value.policy.requestor_justification_required

    dynamic "approval_stage" {
      for_each = each.value.policy.approval_required ? [1] : []
      content {
        approval_timeout_in_days        = each.value.policy.approval_timeout_in_days
        approver_justification_required = true

        dynamic "primary_approver" {
          for_each = each.value.policy.approver_type == "requestorManager" ? [null] : each.value.policy.approver_group_ids
          content {
            subject_type = each.value.policy.approver_type
            object_id    = primary_approver.value
            backup       = false
          }
        }

        dynamic "primary_approver" {
          for_each = toset(each.value.policy.backup_approver_group_ids)
          content {
            subject_type = "groupMembers"
            object_id    = primary_approver.value
            backup       = true
          }
        }
      }
    }
  }

  dynamic "assignment_review_settings" {
    for_each = each.value.policy.review_enabled ? [1] : []
    content {
      enabled                         = true
      review_frequency                = each.value.policy.review_frequency
      review_type                     = each.value.policy.review_type
      duration_in_days                = each.value.policy.review_duration_in_days
      access_review_timeout_behavior  = each.value.policy.review_timeout_behavior
      access_recommendation_enabled   = true
      approver_justification_required = true

      dynamic "reviewer" {
        for_each = each.value.policy.review_type == "Reviewers" ? toset(each.value.policy.reviewer_group_ids) : []
        content {
          subject_type = "groupMembers"
          object_id    = reviewer.value
        }
      }
    }
  }

  depends_on = [azuread_access_package_resource_package_association.group]
}
