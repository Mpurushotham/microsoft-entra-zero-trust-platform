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

variable "waves" {
  description = "Ordered migration waves. One assigned security group is created per wave."
  type        = list(string)
  default     = ["pilot", "wave1", "wave2", "all"]

  validation {
    condition     = length(var.waves) == length(distinct(var.waves)) && alltrue([for w in var.waves : can(regex("^[a-z0-9-]{2,20}$", w))])
    error_message = "waves must be unique, 2-20 chars, lowercase letters, digits or hyphens."
  }

  # Staged rollout accepts at most 10 groups per feature.
  validation {
    condition     = length(var.waves) >= 1 && length(var.waves) <= 10
    error_message = "Staged rollout supports between 1 and 10 groups per feature."
  }
}

variable "enabled_waves" {
  description = "Waves whose group is attached to the feature rollout policies. Advance the migration by appending the next wave."
  type        = list(string)
  default     = []
}

variable "staged_features" {
  description = "Staged rollout features (Graph stagedFeatureName) to create a policy for."
  type        = set(string)
  default     = ["passwordHashSync", "seamlessSso"]

  validation {
    condition = alltrue([for f in var.staged_features : contains([
      "passwordHashSync",
      "passthroughAuthentication",
      "seamlessSso",
      "certificateBasedAuthentication",
      "multiFactorAuthentication",
    ], f)])
    error_message = "Supported features: passwordHashSync, passthroughAuthentication, seamlessSso, certificateBasedAuthentication, multiFactorAuthentication."
  }

  # A user can be staged to one cloud authentication method only.
  validation {
    condition     = !(contains(var.staged_features, "passwordHashSync") && contains(var.staged_features, "passthroughAuthentication"))
    error_message = "passwordHashSync and passthroughAuthentication cannot be staged together; choose one cloud authentication method."
  }
}

variable "rollout_enabled" {
  description = "Sets isEnabled on every feature rollout policy. Set false to pause staged rollout without detaching groups."
  type        = bool
  default     = true
}

variable "group_owners" {
  description = "Object IDs of owners for the wave groups. Empty leaves the deploying principal as owner."
  type        = set(string)
  default     = []
}
