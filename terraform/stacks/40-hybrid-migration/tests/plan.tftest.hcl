# Offline tests with mocked providers: no tenant access. Run: terraform init -backend=false && terraform test
mock_provider "azuread" {
  mock_data "azuread_group" {
    defaults = { object_id = "11111111-1111-1111-1111-111111111111" }
  }
  mock_resource "azuread_group" {
    defaults = { object_id = "22222222-2222-2222-2222-222222222222" }
  }
  mock_resource "azuread_application" {
    defaults = { client_id = "66666666-6666-6666-6666-666666666666" }
  }
  mock_resource "azuread_claims_mapping_policy" {
    defaults = { id = "/policies/claimsMappingPolicies/77777777-7777-7777-7777-777777777777" }
  }
  mock_resource "azuread_service_principal" {
    defaults = { object_id = "33333333-3333-3333-3333-333333333333", id = "/servicePrincipals/33333333-3333-3333-3333-333333333333" }
  }
}
mock_provider "msgraph" {
  mock_resource "msgraph_resource" {
    defaults = { id = "44444444-4444-4444-4444-444444444444" }
  }
}

run "dev" {
  command = apply
  variables {
    environment             = "dev"
    enabled_waves           = ["pilot", "wave1"]
    cloud_managed_group_ids = ["55555555-5555-5555-5555-555555555555"]
    migrated_applications = {
      hr = {
        display_name                   = "hr"
        protocol                       = "saml"
        identifier_uris                = ["https://hr.contoso.com/saml"]
        assign_to_waves                = ["pilot"]
        assignment_group_display_names = ["zt-dev-hr-users"]
        claims_schema                  = [{ ID = "employeeid", Source = "user", SamlClaimType = "x" }]
      }
      exp = {
        display_name  = "exp"
        protocol      = "oidc"
        redirect_uris = ["https://e.contoso.com/signin-oidc"]
      }
    }
  }
  assert {
    condition     = length(module.staged_rollout.feature_rollout_policy_ids) == 2
    error_message = "Expected one feature rollout policy per default staged feature."
  }
}

run "bad_wave" {
  command = plan
  variables {
    environment   = "dev"
    enabled_waves = ["wave9"]
  }
  expect_failures = [var.enabled_waves]
}

