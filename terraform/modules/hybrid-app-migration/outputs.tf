output "applications" {
  description = "App key to client ID, service principal object ID and SSO mode."
  value = {
    for key, sp in azuread_service_principal.app : key => {
      client_id                   = sp.client_id
      service_principal_object_id = sp.object_id
      sso_mode                    = sp.preferred_single_sign_on_mode
      adfs_relying_party          = var.applications[key].adfs_relying_party
    }
  }
}

output "saml_signing_certificate_thumbprints" {
  description = "Thumbprints to hand to each SAML service provider when swapping the IdP from AD FS to Entra."
  value       = { for key, cert in azuread_service_principal_token_signing_certificate.saml : key => cert.thumbprint }
}
