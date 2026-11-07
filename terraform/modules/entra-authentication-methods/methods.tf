locals {
  method_url = "policies/authenticationMethodsPolicy/authenticationMethodConfigurations"

  # Microsoft's well-known ID for the default passkey profile created on migration.
  default_passkey_profile_id = "00000000-0000-0000-0000-000000000001"

  fido2_key_restrictions = {
    isEnforced      = var.fido2.key_restrictions_enforced
    enforcementType = var.fido2.key_restriction_type
    aaGuids         = var.fido2.key_restriction_aaguids
  }

  # jsondecode lets the two body shapes share one conditional.
  fido2_body = jsondecode(var.fido2.use_passkey_profiles ? jsonencode({
    "@odata.type"                    = "#microsoft.graph.fido2AuthenticationMethodConfiguration"
    state                            = var.fido2.enabled ? "enabled" : "disabled"
    isSelfServiceRegistrationAllowed = var.fido2.self_service_registration
    includeTargets = [for id in var.fido2.include_target_ids : {
      targetType             = "group"
      id                     = id
      isRegistrationRequired = false
      allowedPasskeyProfiles = [local.default_passkey_profile_id]
    }]
    passkeyProfiles = [{
      id                     = local.default_passkey_profile_id
      name                   = "Default passkey profile"
      passkeyTypes           = join(",", var.fido2.passkey_types)
      attestationEnforcement = var.fido2.attestation_enforced ? "registrationOnly" : "disabled"
      keyRestrictions        = local.fido2_key_restrictions
    }]
    }) : jsonencode({
    "@odata.type"                    = "#microsoft.graph.fido2AuthenticationMethodConfiguration"
    state                            = var.fido2.enabled ? "enabled" : "disabled"
    isSelfServiceRegistrationAllowed = var.fido2.self_service_registration
    isAttestationEnforced            = var.fido2.attestation_enforced
    keyRestrictions                  = local.fido2_key_restrictions
    includeTargets = [for id in var.fido2.include_target_ids : {
      targetType             = "group"
      id                     = id
      isRegistrationRequired = false
    }]
  }))

  all_users_feature_target = { targetType = "group", id = "all_users" }
  # Graph uses the all-zero GUID to mean "no exclusion" for Authenticator feature settings.
  no_exclusion_feature_target = { targetType = "group", id = "00000000-0000-0000-0000-000000000000" }
}

resource "msgraph_update_resource" "fido2" {
  url  = "${local.method_url}/fido2"
  body = local.fido2_body
}

resource "msgraph_update_resource" "microsoft_authenticator" {
  url = "${local.method_url}/microsoftAuthenticator"
  body = {
    "@odata.type"         = "#microsoft.graph.microsoftAuthenticatorAuthenticationMethodConfiguration"
    state                 = var.microsoft_authenticator.enabled ? "enabled" : "disabled"
    isSoftwareOathEnabled = var.microsoft_authenticator.software_oath_enabled
    featureSettings = {
      displayAppInformationRequiredState = {
        state         = var.microsoft_authenticator.show_application_name ? "enabled" : "disabled"
        includeTarget = local.all_users_feature_target
        excludeTarget = local.no_exclusion_feature_target
      }
      displayLocationInformationRequiredState = {
        state         = var.microsoft_authenticator.show_geographic_location ? "enabled" : "disabled"
        includeTarget = local.all_users_feature_target
        excludeTarget = local.no_exclusion_feature_target
      }
    }
    includeTargets = [for id in var.microsoft_authenticator.include_target_ids : {
      targetType             = "group"
      id                     = id
      isRegistrationRequired = false
      authenticationMode     = var.microsoft_authenticator.authentication_mode
    }]
  }
}

resource "msgraph_update_resource" "temporary_access_pass" {
  url = "${local.method_url}/temporaryAccessPass"
  body = {
    "@odata.type"            = "#microsoft.graph.temporaryAccessPassAuthenticationMethodConfiguration"
    state                    = var.temporary_access_pass.enabled ? "enabled" : "disabled"
    defaultLifetimeInMinutes = var.temporary_access_pass.default_lifetime_in_minutes
    minimumLifetimeInMinutes = var.temporary_access_pass.minimum_lifetime_in_minutes
    maximumLifetimeInMinutes = var.temporary_access_pass.maximum_lifetime_in_minutes
    defaultLength            = var.temporary_access_pass.default_length
    isUsableOnce             = var.temporary_access_pass.is_usable_once
    includeTargets = [for id in var.temporary_access_pass.include_target_ids : {
      targetType             = "group"
      id                     = id
      isRegistrationRequired = false
    }]
  }
}

resource "msgraph_update_resource" "sms" {
  url = "${local.method_url}/sms"
  body = {
    "@odata.type" = "#microsoft.graph.smsAuthenticationMethodConfiguration"
    state         = var.disable_sms ? "disabled" : "enabled"
  }
}

resource "msgraph_update_resource" "voice" {
  url = "${local.method_url}/voice"
  body = {
    "@odata.type" = "#microsoft.graph.voiceAuthenticationMethodConfiguration"
    state         = var.disable_voice ? "disabled" : "enabled"
  }
}

resource "msgraph_update_resource" "policy" {
  url = "policies/authenticationMethodsPolicy"
  body = merge(
    {
      registrationEnforcement = {
        authenticationMethodsRegistrationCampaign = {
          state                = var.registration_campaign.enabled ? "enabled" : "disabled"
          snoozeDurationInDays = var.registration_campaign.snooze_duration_in_days
          includeTargets = [{
            targetType                   = "group"
            id                           = "all_users"
            targetedAuthenticationMethod = var.registration_campaign.targeted_method
          }]
          excludeTargets = [for id in var.excluded_group_ids : { targetType = "group", id = id }]
        }
      }
    },
    var.complete_policy_migration ? { policyMigrationState = "migrationComplete" } : {}
  )

  # The campaign must not target a method that is still disabled.
  depends_on = [
    msgraph_update_resource.fido2,
    msgraph_update_resource.microsoft_authenticator,
  ]
}
