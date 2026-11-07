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

variable "policies" {
  type    = set(string)
  default = ["antivirus", "firewall", "asr", "edr", "bitlocker", "laps"]

  validation {
    condition     = alltrue([for p in var.policies : contains(["antivirus", "firewall", "asr", "edr", "bitlocker", "laps"], p)])
    error_message = "policies may only contain antivirus, firewall, asr, edr, bitlocker, laps."
  }
}

variable "antivirus" {
  type = object({
    cloud_block_level  = optional(string, "high")
    network_protection = optional(string, "block")
    sample_submission  = optional(string, "safe")
  })
  default = {}

  validation {
    condition = (
      contains(["default", "high", "high_plus", "zero_tolerance"], var.antivirus.cloud_block_level) &&
      contains(["block", "audit"], var.antivirus.network_protection) &&
      contains(["safe", "all"], var.antivirus.sample_submission)
    )
    error_message = "cloud_block_level: default|high|high_plus|zero_tolerance; network_protection: block|audit; sample_submission: safe|all."
  }
}

variable "firewall_public_allow_local_rule_merge" {
  type        = bool
  default     = false
  description = "Whether locally created firewall rules apply on the public profile."
}

variable "asr_rules" {
  type        = map(string)
  default     = {}
  description = "Overrides of ASR rule modes (off, audit, warn, block) keyed by rule name, merged over the defaults in locals."

  validation {
    condition     = alltrue([for m in values(var.asr_rules) : contains(["off", "audit", "warn", "block"], m)])
    error_message = "ASR rule modes must be off, audit, warn or block."
  }
}

variable "bitlocker" {
  type = object({
    os_drive_method        = optional(string, "xts_aes_256")
    fixed_drive_method     = optional(string, "xts_aes_256")
    removable_drive_method = optional(string, "aes_cbc_256")
  })
  default = {}

  validation {
    condition = alltrue([
      for m in values(var.bitlocker) : contains(["aes_cbc_128", "aes_cbc_256", "xts_aes_128", "xts_aes_256"], m)
    ])
    error_message = "BitLocker methods must be aes_cbc_128, aes_cbc_256, xts_aes_128 or xts_aes_256."
  }
}

variable "laps" {
  type = object({
    password_age_days                     = optional(number, 30)
    password_length                       = optional(number, 21)
    password_complexity                   = optional(number, 4)
    post_authentication_action            = optional(string, "reset_and_logoff")
    post_authentication_reset_delay_hours = optional(number, 8)
  })
  default = {}

  validation {
    condition = (
      var.laps.password_age_days >= 7 && var.laps.password_age_days <= 365 &&
      var.laps.password_length >= 14 && var.laps.password_length <= 64 &&
      contains([3, 4, 5], var.laps.password_complexity) &&
      var.laps.post_authentication_reset_delay_hours >= 0 && var.laps.post_authentication_reset_delay_hours <= 24 &&
      contains(["reset", "reset_and_logoff", "reset_and_reboot", "reset_logoff_and_terminate"], var.laps.post_authentication_action)
    )
    error_message = "LAPS: age 7-365 days, length 14-64, complexity 3-5, reset delay 0-24h, action reset|reset_and_logoff|reset_and_reboot|reset_logoff_and_terminate."
  }
}

variable "assignments" {
  type = map(object({
    include_group_ids = list(string)
    exclude_group_ids = optional(list(string), [])
  }))
  default     = {}
  description = "Group assignments keyed by policy key."
}
