locals {
  baseline_groups = {
    # Personas (Zero Trust persona-based Conditional Access framework)
    "persona-internals" = {
      description  = "All enabled member (employee) accounts."
      dynamic_rule = "(user.userType -eq \"Member\") -and (user.accountEnabled -eq true)"
    }
    "persona-guests" = {
      description  = "All B2B guest accounts."
      dynamic_rule = "(user.userType -eq \"Guest\")"
    }
    "persona-admins" = {
      description        = "Dedicated, cloud-only administrator accounts (separate from daily-use accounts)."
      assignable_to_role = true
    }
    "persona-developers" = {
      description = "Developers. Membership granted through the developers access package."
    }
    "persona-external-partners" = {
      description = "Partner guests granted collaboration access through an access package."
    }
    "persona-service-accounts" = {
      description        = "Legacy user-based service accounts that cannot use workload identities. Excluded from interactive MFA policies; reviewed quarterly."
      assignable_to_role = true
    }
    "governance-partner-sponsors" = {
      description = "Approvers for partner access requests."
    }
    "ca-pilot-users" = {
      description = "Pilot ring for new Conditional Access and token protection policies."
    }
    "users-new-hires" = {
      description = "Joiners added by the day-one lifecycle workflow; used for onboarding apps and ESP targeting."
    }

    # Privileged access groups. Role-assignable so only Privileged Role Administrators can change them.
    "pim-approvers" = {
      description        = "Approvers for Tier-0 role activation and privileged access packages."
      assignable_to_role = true
    }
    "pim-global-administrators" = {
      description        = "Tier 0. Eligible for Global Administrator."
      assignable_to_role = true
    }
    "pim-privileged-role-administrators" = {
      description        = "Tier 0. Eligible for Privileged Role Administrator."
      assignable_to_role = true
    }
    "pim-privileged-authentication-administrators" = {
      description        = "Tier 0. Eligible for Privileged Authentication Administrator."
      assignable_to_role = true
    }
    "pim-security-administrators" = {
      description        = "Tier 1. Just-in-time members hold Security Administrator."
      assignable_to_role = true
    }
    "pim-conditional-access-administrators" = {
      description        = "Tier 1. Just-in-time members hold Conditional Access Administrator."
      assignable_to_role = true
    }
    "pim-intune-administrators" = {
      description        = "Tier 1. Just-in-time members hold Intune Administrator."
      assignable_to_role = true
    }
    "pim-user-administrators" = {
      description        = "Tier 1. Just-in-time members hold User Administrator."
      assignable_to_role = true
    }
    "pim-helpdesk-administrators" = {
      description        = "Tier 2. Just-in-time members hold Helpdesk Administrator scoped to the standard users administrative unit."
      assignable_to_role = true
    }
    "pim-global-readers" = {
      description        = "Tier 1. Just-in-time members hold Global Reader."
      assignable_to_role = true
    }
    "pim-security-readers" = {
      description        = "Tier 1. Just-in-time members hold Security Reader."
      assignable_to_role = true
    }
  }

  groups = merge(local.baseline_groups, var.additional_groups)

  administrative_units = {
    "users-standard" = {
      description = "Standard workforce users the service desk may manage."
    }
    "devices-corporate" = {
      description = "Corporate devices managed by regional device administrators."
    }
    "tier0-accounts" = {
      description = "Emergency access and Tier-0 admin accounts. No roles are scoped here; used for reporting and to keep Tier-0 objects out of delegated AUs."
    }
  }

  role_template_ids = {
    helpdesk_administrator = "729827e3-9c14-49f7-bb1b-9608f156bbb8"
  }

  authentication_strengths = {
    "phishing-resistant-admins" = {
      description          = "Phishing-resistant MFA for privileged roles: passkey (FIDO2), Windows Hello for Business or certificate-based MFA."
      allowed_combinations = ["fido2", "windowsHelloForBusiness", "x509CertificateMultiFactor"]
    }
    "passwordless-mfa" = {
      description          = "Passwordless MFA for the workforce, including Authenticator phone sign-in."
      allowed_combinations = ["fido2", "windowsHelloForBusiness", "x509CertificateMultiFactor", "deviceBasedPush"]
    }
    "security-info-registration" = {
      description          = "Bootstrap strength for registering security info: one-time Temporary Access Pass or an existing strong method."
      allowed_combinations = ["temporaryAccessPassOneTime", "fido2", "windowsHelloForBusiness", "deviceBasedPush", "password,microsoftAuthenticatorPush"]
    }
  }

  custom_security_attribute_sets = {
    "ZeroTrust" = {
      description = "Classification attributes used for Conditional Access filters and governance scoping."
      attributes = {
        "AdminTier" = {
          description                 = "Administrative tier of the account (Tier0, Tier1, Tier2)."
          use_pre_defined_values_only = false
        }
        "DataClassification" = {
          description = "Highest data classification the application handles."
        }
      }
    }
  }
}
