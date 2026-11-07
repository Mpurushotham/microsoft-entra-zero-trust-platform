locals {
  recurrence = {
    for months in [1, 3, 6, 12] : months => {
      pattern = {
        type       = "absoluteMonthly"
        interval   = months
        dayOfMonth = 1
      }
      range = {
        type      = "noEnd"
        startDate = var.start_date
      }
    }
  }

  group_review_bodies = {
    for k, r in var.group_membership_reviews : k => {
      displayName             = "${var.name_prefix}-${var.environment}-ar-${k}"
      descriptionForAdmins    = r.description
      descriptionForReviewers = "Confirm each member still needs this access. Unreviewed access is ${r.default_decision == "Deny" ? "removed" : "kept"} when the review ends."
      scope = {
        "@odata.type" = "#microsoft.graph.accessReviewQueryScope"
        query         = r.guests_only ? "/groups/${r.group_object_id}/transitiveMembers/microsoft.graph.user/?$filter=(userType eq 'Guest')" : "/groups/${r.group_object_id}/transitiveMembers"
        queryType     = "MicrosoftGraph"
      }
      reviewers = concat(
        r.reviewer_is_manager ? [{ query = "./manager", queryType = "MicrosoftGraph", queryRoot = "decisions" }] : [],
        [for g in r.reviewer_group_object_ids : { query = "/groups/${g}/transitiveMembers", queryType = "MicrosoftGraph" }],
      )
      fallbackReviewers = [for g in r.fallback_group_object_ids : { query = "/groups/${g}/transitiveMembers", queryType = "MicrosoftGraph" }]
      settings = {
        mailNotificationsEnabled        = true
        reminderNotificationsEnabled    = true
        justificationRequiredOnApproval = true
        recommendationsEnabled          = true
        defaultDecisionEnabled          = r.default_decision != "None"
        defaultDecision                 = r.default_decision
        autoApplyDecisionsEnabled       = r.auto_apply
        instanceDurationInDays          = r.duration_in_days
        recurrence                      = local.recurrence[r.recurrence_months]
      }
    }
  }

  inactive_guest_body = {
    displayName             = "${var.name_prefix}-${var.environment}-ar-inactive-guests-m365-groups"
    descriptionForAdmins    = "Removes guests who have not signed in for ${var.inactive_guest_review.inactive_days} days from Microsoft 365 groups."
    descriptionForReviewers = "These guests have not signed in recently. Approve only if they still collaborate with your team."
    instanceEnumerationScope = {
      "@odata.type" = "#microsoft.graph.accessReviewQueryScope"
      query         = "/groups?$filter=(groupTypes/any(c:c+eq+'Unified'))"
      queryType     = "MicrosoftGraph"
    }
    scope = {
      "@odata.type"    = "#microsoft.graph.accessReviewInactiveUsersQueryScope"
      query            = "./members/microsoft.graph.user/?$filter=(userType eq 'Guest')"
      queryType        = "MicrosoftGraph"
      inactiveDuration = "P${var.inactive_guest_review.inactive_days}D"
    }
    reviewers         = [{ query = "./owners", queryType = "MicrosoftGraph" }]
    fallbackReviewers = [for g in var.inactive_guest_review.fallback_group_object_ids : { query = "/groups/${g}/transitiveMembers", queryType = "MicrosoftGraph" }]
    settings = {
      mailNotificationsEnabled        = true
      reminderNotificationsEnabled    = true
      justificationRequiredOnApproval = true
      recommendationsEnabled          = true
      defaultDecisionEnabled          = true
      defaultDecision                 = "Deny"
      autoApplyDecisionsEnabled       = true
      instanceDurationInDays          = var.inactive_guest_review.duration_in_days
      recurrence                      = local.recurrence[var.inactive_guest_review.recurrence_months]
    }
  }
}

resource "msgraph_resource" "group_membership" {
  for_each = local.group_review_bodies

  url  = "identityGovernance/accessReviews/definitions"
  body = each.value
}

resource "msgraph_resource" "inactive_guests" {
  count = var.inactive_guest_review.enabled ? 1 : 0

  url  = "identityGovernance/accessReviews/definitions"
  body = local.inactive_guest_body
}
