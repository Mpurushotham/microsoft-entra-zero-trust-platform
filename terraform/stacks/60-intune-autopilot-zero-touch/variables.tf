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

variable "autopilot_profiles" {
  type = map(object({
    mode                  = string
    allow_preprovisioning = optional(bool, false)
    device_name_template  = optional(string)
    group_tag             = string
  }))
  default = {
    user_driven = {
      mode                 = "user_driven"
      device_name_template = "CORP-%RAND:6%"
      group_tag            = "CORP-WIN"
    }
    pre_provisioned = {
      mode                  = "user_driven"
      allow_preprovisioning = true
      device_name_template  = "CORP-%RAND:6%"
      group_tag             = "PREPROV"
    }
    self_deploying = {
      mode                 = "self_deploying"
      device_name_template = "KIOSK-%RAND:5%"
      group_tag            = "KIOSK"
    }
  }
  description = "Autopilot profiles keyed by name. Each is assigned to a dynamic group of devices imported with the matching group tag (OrderID)."

  validation {
    condition     = alltrue([for p in values(var.autopilot_profiles) : can(regex("^[A-Z0-9-]{1,32}$", p.group_tag))])
    error_message = "group_tag must be 1-32 uppercase letters, digits or hyphens."
  }

  validation {
    condition     = length(distinct([for p in values(var.autopilot_profiles) : p.group_tag])) == length(var.autopilot_profiles)
    error_message = "Each profile needs a unique group_tag so a device resolves to exactly one profile."
  }
}

variable "esp_timeout_minutes" {
  type    = number
  default = 60

  validation {
    condition     = var.esp_timeout_minutes >= 15 && var.esp_timeout_minutes <= 1440
    error_message = "esp_timeout_minutes must be between 15 and 1440."
  }
}

variable "esp_allow_use_on_failure" {
  type    = bool
  default = false
}

variable "enable_device_preparation_group" {
  type        = bool
  default     = true
  description = "Create the device group used by an Autopilot device preparation policy, owned by the Intune Provisioning Client service principal."
}

variable "intune_provisioning_client_app_id" {
  type        = string
  default     = "f1346770-5b25-470b-88bd-d5744ab7952c"
  description = "First-party application ID of Intune Provisioning Client. Its service principal must exist in the tenant."

  validation {
    condition     = can(regex("^[0-9a-f-]{36}$", var.intune_provisioning_client_app_id))
    error_message = "intune_provisioning_client_app_id must be a GUID."
  }
}

variable "android_zero_touch_enabled" {
  type    = bool
  default = false
}

variable "apple_dep_onboarding_setting_id" {
  type        = string
  default     = null
  description = "ID of the Apple Business Manager token already uploaded to Intune; null skips the ADE enrollment profile."
}

variable "support_phone_number" {
  type    = string
  default = ""
}
