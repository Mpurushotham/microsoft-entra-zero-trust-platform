module "access_reviews" {
  source = "../../modules/entra-access-reviews"

  name_prefix = var.name_prefix
  environment = var.environment
  start_date  = var.access_review_start_date

  group_membership_reviews = merge(
    {
      for group_key in keys(local.tier0_groups) : group_key => {
        group_object_id           = local.group_ids[group_key]
        description               = "Monthly attestation of Tier-0 privileged group membership."
        reviewer_group_object_ids = [local.approvers]
        recurrence_months         = 1
        duration_in_days          = 7
      }
    },
    {
      for group_key in local.jit_groups : group_key => {
        group_object_id           = local.group_ids[group_key]
        description               = "Quarterly review of members of a privileged access group."
        reviewer_group_object_ids = [local.approvers]
      }
    },
    {
      # Never auto-remove: losing an emergency account would defeat its purpose.
      "ca-exclude-emergency-access" = {
        group_object_id           = local.group_ids["ca-exclude-emergency-access"]
        description               = "Quarterly confirmation that only the emergency access accounts are excluded from Conditional Access."
        reviewer_group_object_ids = [local.approvers]
        default_decision          = "None"
        auto_apply                = false
      }
      "persona-service-accounts" = {
        group_object_id           = local.group_ids["persona-service-accounts"]
        description               = "Quarterly review of user-based service accounts excluded from interactive MFA."
        reviewer_group_object_ids = [local.approvers]
        default_decision          = "None"
        auto_apply                = false
      }
    },
  )

  inactive_guest_review = {
    enabled                   = true
    inactive_days             = 90
    fallback_group_object_ids = [local.group_ids["governance-partner-sponsors"]]
  }
}
