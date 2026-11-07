module "entitlement_management" {
  source = "../../modules/entra-entitlement-management"

  name_prefix = var.name_prefix
  environment = var.environment

  catalogs = {
    "privileged-access" = {
      description = "Tier-0 privileged access groups. Requests need approval by the PIM approvers group."
    }
    "workforce" = {
      description = "Workforce and partner collaboration access."
    }
    "partners" = {
      description        = "Access that external partners can request."
      externally_visible = true
    }
  }

  access_packages = merge(
    {
      for group_key in keys(local.tier0_groups) : trimprefix(group_key, "pim-") => {
        catalog_key = "privileged-access"
        description = "Membership of ${local.name}-${group_key}, which is PIM-eligible for the role. Dedicated admin accounts only."
        hidden      = true
        group_ids   = [local.group_ids[group_key]]
        policy = {
          requestor_scope_type     = "SpecificDirectorySubjects"
          requestor_group_ids      = [local.group_ids["persona-admins"]]
          duration_in_days         = 90
          approver_type            = "groupMembers"
          approver_group_ids       = [local.approvers]
          approval_timeout_in_days = 3
          review_frequency         = "quarterly"
          review_type              = "Reviewers"
          reviewer_group_ids       = [local.approvers]
          review_timeout_behavior  = "removeAccess"
        }
      }
    },
    {
      "developers" = {
        catalog_key = "workforce"
        description = "Developer tooling and non-production access."
        group_ids   = [local.group_ids["persona-developers"]]
        policy = {
          requestor_scope_type = "AllExistingDirectoryMemberUsers"
          duration_in_days     = 180
          approver_type        = "requestorManager"
          review_frequency     = "quarterly"
          review_type          = "Manager"
        }
      }
      "external-partners" = {
        catalog_key = "partners"
        description = "Collaboration access for partner guests, sponsored internally."
        group_ids   = [local.group_ids["persona-external-partners"]]
        policy = {
          requestor_scope_type = "AllExistingDirectorySubjects"
          duration_in_days     = 90
          extension_enabled    = false
          approver_type        = "groupMembers"
          approver_group_ids   = [local.group_ids["governance-partner-sponsors"]]
          review_frequency     = "quarterly"
          review_type          = "Reviewers"
          reviewer_group_ids   = [local.group_ids["governance-partner-sponsors"]]
        }
      }
    },
  )
}
