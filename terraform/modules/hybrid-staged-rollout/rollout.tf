locals {
  feature_labels = {
    passwordHashSync               = "Password hash sync"
    passthroughAuthentication      = "Pass-through authentication"
    seamlessSso                    = "Seamless SSO"
    certificateBasedAuthentication = "Certificate-based authentication"
    multiFactorAuthentication      = "Entra MFA"
  }

  policy_wave_pairs = {
    for pair in setproduct(var.staged_features, var.enabled_waves) :
    "${pair[0]}/${pair[1]}" => { feature = pair[0], wave = pair[1] }
  }
}

resource "msgraph_resource" "feature_rollout_policy" {
  for_each = var.staged_features

  url = "policies/featureRolloutPolicies"
  body = {
    displayName = "${var.name_prefix}-${var.environment}-staged-rollout-${each.key}"
    description = "Staged rollout of ${local.feature_labels[each.key]} for federated domains."
    feature     = each.key
    isEnabled   = var.rollout_enabled
    # Graph reserves org-wide application; staged rollout always targets groups.
    isAppliedToOrganization = false
  }
}

resource "msgraph_resource" "feature_rollout_applies_to" {
  for_each = local.policy_wave_pairs

  url = "policies/featureRolloutPolicies/${msgraph_resource.feature_rollout_policy[each.value.feature].id}/appliesTo/$ref"
  body = {
    "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/${azuread_group.wave[each.value.wave].object_id}"
  }

  lifecycle {
    precondition {
      condition     = contains(var.waves, each.value.wave)
      error_message = "enabled_waves contains '${each.value.wave}', which is not declared in waves."
    }
  }
}
