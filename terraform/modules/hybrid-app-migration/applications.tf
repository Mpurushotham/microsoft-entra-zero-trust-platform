locals {
  # Microsoft's "non-gallery application" template, used for custom SAML apps.
  non_gallery_template_id = "8adf8e6e-67b2-4cf2-a259-e3dc5476c621"

  apps = {
    for key, app in var.applications : key => merge(app, {
      resolved_template_id = app.template_id != null ? app.template_id : (app.protocol == "saml" ? local.non_gallery_template_id : null)
    })
  }

  saml_apps = { for key, app in local.apps : key => app if app.protocol == "saml" }

  assignments = merge([
    for key, app in local.apps : {
      for label, group_id in app.assignment_groups : "${key}/${label}" => { app = key, group = group_id }
    }
  ]...)
}

resource "azuread_application" "app" {
  for_each = local.apps

  display_name            = "${var.name_prefix}-${var.environment}-${each.value.display_name}"
  template_id             = each.value.resolved_template_id
  identifier_uris         = each.value.identifier_uris
  group_membership_claims = length(each.value.group_membership_claims) > 0 ? each.value.group_membership_claims : null
  owners                  = length(each.value.owners) > 0 ? each.value.owners : null
  notes                   = each.value.adfs_relying_party != null ? "Migrated from AD FS relying party trust: ${each.value.adfs_relying_party}" : null

  web {
    homepage_url  = each.value.homepage_url
    logout_url    = each.value.logout_url
    redirect_uris = each.value.redirect_uris

    implicit_grant {
      access_token_issuance_enabled = false
      id_token_issuance_enabled     = false
    }
  }

  # Custom claims on SAML/OIDC tokens are issued only when the app accepts mapped claims.
  dynamic "api" {
    for_each = length(each.value.claims_schema) > 0 ? [1] : []
    content {
      mapped_claims_enabled = true
    }
  }
}

resource "azuread_service_principal" "app" {
  for_each = local.apps

  client_id = azuread_application.app[each.key].client_id
  # Template instantiation creates the service principal alongside the application.
  use_existing                  = each.value.resolved_template_id != null
  app_role_assignment_required  = each.value.app_role_assignment_required
  preferred_single_sign_on_mode = each.value.protocol
  login_url                     = each.value.login_url
  notification_email_addresses  = each.value.notification_email_addresses
  owners                        = length(each.value.owners) > 0 ? each.value.owners : null

  feature_tags {
    enterprise            = true
    custom_single_sign_on = each.value.protocol == "saml" && each.value.template_id == null
    gallery               = each.value.template_id != null
    hide                  = each.value.hide_from_my_apps
  }

  dynamic "saml_single_sign_on" {
    for_each = each.value.protocol == "saml" && each.value.relay_state != null ? [each.value.relay_state] : []
    content {
      relay_state = saml_single_sign_on.value
    }
  }
}

resource "azuread_service_principal_token_signing_certificate" "saml" {
  for_each = local.saml_apps

  service_principal_id = azuread_service_principal.app[each.key].id
  display_name         = "CN=${var.name_prefix}-${var.environment}-${each.value.display_name}"
  end_date             = each.value.signing_certificate_end_date
}

# azuread has no argument for the preferred signing key, so Graph is patched directly.
resource "msgraph_update_resource" "saml_preferred_signing_key" {
  for_each = local.saml_apps

  url = "servicePrincipals/${azuread_service_principal.app[each.key].object_id}"
  body = {
    preferredTokenSigningKeyThumbprint = azuread_service_principal_token_signing_certificate.saml[each.key].thumbprint
  }
}

resource "azuread_app_role_assignment" "group" {
  for_each = local.assignments

  # Default access role: the apps migrated from AD FS publish no custom roles.
  app_role_id         = "00000000-0000-0000-0000-000000000000"
  principal_object_id = each.value.group
  resource_object_id  = azuread_service_principal.app[each.value.app].object_id
}
