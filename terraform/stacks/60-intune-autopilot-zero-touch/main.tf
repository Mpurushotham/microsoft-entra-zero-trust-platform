module "autopilot" {
  source = "../../modules/intune-autopilot"

  name_prefix = var.name_prefix
  environment = var.environment

  deployment_profiles = {
    for k, p in var.autopilot_profiles : k => {
      mode                  = p.mode
      allow_preprovisioning = p.allow_preprovisioning
      device_name_template  = p.device_name_template
      include_group_ids     = [azuread_group.group_tag[k].object_id]
    }
  }

  enrollment_status_page = {
    timeout_minutes      = var.esp_timeout_minutes
    allow_use_on_failure = var.esp_allow_use_on_failure
    include_group_ids    = [azuread_group.autopilot_all.object_id]
  }

  required_app_group_ids = [azuread_group.autopilot_all.object_id]

  android_zero_touch = {
    enabled = var.android_zero_touch_enabled
  }

  apple_ade = {
    dep_onboarding_setting_id = var.apple_dep_onboarding_setting_id
    support_phone_number      = var.support_phone_number
  }
}
