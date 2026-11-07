variable "name_prefix" {
  type    = string
  default = "zt"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,9}$", var.name_prefix))
    error_message = "name_prefix must be 2-10 lowercase alphanumeric characters starting with a letter."
  }
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "role_scope_tag_ids" {
  type        = list(string)
  default     = ["0"]
  description = "Intune scope tag IDs applied to every object. \"0\" is the built-in Default tag."
}

variable "deployment_profiles" {
  type = map(object({
    mode                  = string
    allow_preprovisioning = optional(bool, false)
    device_name_template  = optional(string)
    locale                = optional(string, "os-default")
    user_type             = optional(string, "standard")
    include_group_ids     = list(string)
    exclude_group_ids     = optional(list(string), [])
  }))
  description = "Windows Autopilot deployment profiles keyed by short name. mode is user_driven or self_deploying; all profiles join Microsoft Entra ID."

  validation {
    condition     = alltrue([for p in values(var.deployment_profiles) : contains(["user_driven", "self_deploying"], p.mode)])
    error_message = "mode must be user_driven or self_deploying."
  }

  validation {
    condition     = alltrue([for p in values(var.deployment_profiles) : !(p.mode == "self_deploying" && p.allow_preprovisioning)])
    error_message = "Pre-provisioning applies to user-driven profiles only."
  }

  validation {
    condition     = alltrue([for p in values(var.deployment_profiles) : p.device_name_template == null || can(regex("^[A-Za-z0-9-]{1,14}(%SERIAL%|%RAND:[0-9]{1,2}%)?$", p.device_name_template))])
    error_message = "device_name_template is a short literal prefix optionally followed by %SERIAL% or %RAND:x%; Windows truncates names to 15 characters."
  }

  validation {
    condition     = alltrue([for p in values(var.deployment_profiles) : contains(["standard", "administrator"], p.user_type)])
    error_message = "user_type must be standard or administrator."
  }
}

variable "enrollment_status_page" {
  type = object({
    timeout_minutes         = optional(number, 60)
    blocking_app_ids        = optional(list(string), [])
    allow_reset_on_failure  = optional(bool, true)
    allow_use_on_failure    = optional(bool, false)
    install_quality_updates = optional(bool, true)
    custom_error_message    = optional(string, "Setup could not be completed. Contact the service desk and quote the error on this screen.")
    priority                = optional(number, 1)
    include_group_ids       = list(string)
  })
  description = "Enrollment Status Page assigned to Autopilot device groups. Tracking device-targeted apps keeps users out of the desktop until the baseline is in place."

  validation {
    condition     = var.enrollment_status_page.timeout_minutes >= 15 && var.enrollment_status_page.timeout_minutes <= 1440
    error_message = "timeout_minutes must be between 15 and 1440."
  }

  validation {
    condition     = var.enrollment_status_page.priority >= 1
    error_message = "Priority 0 is reserved for the tenant default ESP."
  }
}

variable "required_store_apps" {
  type = map(object({
    display_name       = string
    publisher          = string
    package_identifier = string
    run_as_account     = optional(string, "system")
    block_esp          = optional(bool, true)
  }))
  default = {
    company_portal = {
      display_name       = "Company Portal"
      publisher          = "Microsoft Corporation"
      package_identifier = "9WZDNCRFJ3PZ"
    }
  }
  description = "Microsoft Store (WinGet) apps installed as required during provisioning, keyed by short name."

  validation {
    condition     = alltrue([for a in values(var.required_store_apps) : contains(["system", "user"], a.run_as_account)])
    error_message = "run_as_account must be system or user."
  }
}

variable "required_app_group_ids" {
  type        = list(string)
  default     = []
  description = "Device groups that receive required_store_apps."
}

variable "android_zero_touch" {
  type = object({
    enabled = bool
  })
  default = {
    enabled = false
  }
  description = "Create the Android Enterprise corporate-owned fully managed enrollment profile used by the zero-touch portal DPC extras."
}

variable "apple_ade" {
  type = object({
    dep_onboarding_setting_id = optional(string)
    support_phone_number      = optional(string, "")
    support_department        = optional(string, "IT Service Desk")
  })
  default     = {}
  description = "Apple Automated Device Enrollment. Supply the ID of an already uploaded Apple Business Manager token to create the enrollment profile."

  validation {
    condition     = var.apple_ade.dep_onboarding_setting_id == null || can(regex("^[0-9a-fA-F-]{36}$", var.apple_ade.dep_onboarding_setting_id))
    error_message = "dep_onboarding_setting_id must be a GUID."
  }
}
