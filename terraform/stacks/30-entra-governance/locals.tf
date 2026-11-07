locals {
  name = "${var.name_prefix}-${var.environment}"

  roles = {
    global_administrator                    = "62e90394-69f5-4237-9190-012177145e10"
    privileged_role_administrator           = "e8611ab8-c189-46e8-94e1-60213ab1f814"
    privileged_authentication_administrator = "7be44c8a-adaf-4e2a-84d6-ab2649e08a13"
    security_administrator                  = "194ae4cb-b126-40b2-bd5b-6091b380977d"
    conditional_access_administrator        = "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9"
    intune_administrator                    = "3a2c62db-5318-420d-8d74-23affee5d9d5"
    user_administrator                      = "fe930be7-5e62-47db-91af-98c3a49a38b1"
    global_reader                           = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
    security_reader                         = "5d6b6bb7-de71-4623-b4af-96380a352509"
  }

  # Tier 0: group is PIM-eligible for the role; membership via approved access package.
  tier0_groups = {
    "pim-global-administrators"                    = local.roles.global_administrator
    "pim-privileged-role-administrators"           = local.roles.privileged_role_administrator
    "pim-privileged-authentication-administrators" = local.roles.privileged_authentication_administrator
  }

  # Tier 1: group holds the role actively; users are PIM-eligible members.
  tier1_groups = {
    "pim-security-administrators"           = local.roles.security_administrator
    "pim-conditional-access-administrators" = local.roles.conditional_access_administrator
    "pim-intune-administrators"             = local.roles.intune_administrator
    "pim-user-administrators"               = local.roles.user_administrator
    "pim-global-readers"                    = local.roles.global_reader
    "pim-security-readers"                  = local.roles.security_reader
  }

  # Helpdesk role is scoped to an administrative unit in stack 10; only its JIT membership is managed here.
  jit_groups = concat(keys(local.tier1_groups), ["pim-helpdesk-administrators"])

  lookup_groups = toset(concat(
    keys(local.tier0_groups),
    local.jit_groups,
    [
      "pim-approvers",
      "persona-admins",
      "persona-developers",
      "persona-external-partners",
      "persona-service-accounts",
      "governance-partner-sponsors",
      "users-new-hires",
      "ca-exclude-emergency-access",
    ],
  ))

  group_ids = { for k, g in data.azuread_group.this : k => g.object_id }
  approvers = local.group_ids["pim-approvers"]

  eligible_members = merge([
    for group_key, upns in var.pim_eligible_members : {
      for upn in upns : "${group_key}/${upn}" => {
        group_key = group_key
        upn       = upn
      }
    }
  ]...)

  hours = { for h in range(1, 24) : h => "PT${h}H" }

  lifecycle_tasks = {
    enable_account             = "6fc52c9d-398b-4305-9763-15f42c1676fc"
    send_welcome_email         = "70b29d51-b59a-4773-9280-8841dfd3f2ea"
    onboarding_reminder        = "3c860712-2d37-42a4-928f-5c93935d26a1"
    generate_tap               = "1b555e50-7f65-41d5-b514-5894a026d10d"
    add_to_groups              = "22085229-5809-45e8-97fd-270d28d66910"
    notify_manager_of_move     = "aab41899-9972-422a-9d97-f626014578b7"
    disable_account            = "1dfdfcc7-52fa-4c2e-bf3a-e3919cc12950"
    revoke_refresh_tokens      = "509589a4-0466-4471-829e-49c5e502bdee"
    remove_from_all_groups     = "b3a31406-2a15-4c9a-b25b-a658fa5f07fc"
    remove_from_all_teams      = "81f7b200-2816-4b3b-8c5d-dc556f07b024"
    remove_all_access_packages = "42ae2956-193d-4f39-be06-691b8ac4fa1d"
    send_email_on_last_day     = "9c0a1eaf-5bda-4392-9d9e-6e155bb57411"
    remove_all_licenses        = "8fa97d28-3e52-4985-b3a9-a1126f9b8b4e"
    delete_account             = "8d18588d-9ad3-4c0f-99d0-ec215f0e3dff"
  }
}
