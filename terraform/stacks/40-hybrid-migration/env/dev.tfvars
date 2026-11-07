name_prefix = "zt"
environment = "dev"

migration_waves        = ["pilot", "wave1", "wave2", "all"]
enabled_waves          = ["pilot"]
staged_features        = ["passwordHashSync", "seamlessSso"]
staged_rollout_enabled = true

migrated_applications = {
  hr-portal = {
    display_name       = "hr-portal"
    protocol           = "saml"
    adfs_relying_party = "https://hr.contoso.com/saml"
    identifier_uris    = ["https://hr.contoso.com/saml"]
    redirect_uris      = ["https://hr.contoso.com/saml/acs"]
    logout_url         = "https://hr.contoso.com/saml/logout"
    assign_to_waves    = ["pilot"]
    claims_schema = [
      {
        ID            = "employeeid"
        Source        = "user"
        SamlClaimType = "http://schemas.contoso.com/identity/claims/employeeid"
      }
    ]
  }

  expenses = {
    display_name            = "expenses"
    protocol                = "oidc"
    adfs_relying_party      = "urn:contoso:expenses"
    redirect_uris           = ["https://expenses.contoso.com/signin-oidc"]
    logout_url              = "https://expenses.contoso.com/signout-oidc"
    group_membership_claims = ["SecurityGroup"]
    assign_to_waves         = ["pilot"]
  }
}

cloud_managed_group_ids = []
