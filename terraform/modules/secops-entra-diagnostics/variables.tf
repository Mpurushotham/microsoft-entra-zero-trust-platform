variable "name" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "log_categories" {
  type        = set(string)
  nullable    = false
  description = "Entra ID log categories. Risk categories need Entra ID P2; MicrosoftGraphActivityLogs is billed per GB ingested."
  default = [
    "AuditLogs",
    "SignInLogs",
    "NonInteractiveUserSignInLogs",
    "ServicePrincipalSignInLogs",
    "ManagedIdentitySignInLogs",
    "ProvisioningLogs",
    "RiskyUsers",
    "UserRiskEvents",
    "RiskyServicePrincipals",
    "ServicePrincipalRiskEvents",
    "MicrosoftGraphActivityLogs",
  ]

  validation {
    condition = length(var.log_categories) > 0 && alltrue([for c in var.log_categories : contains([
      "AuditLogs",
      "SignInLogs",
      "NonInteractiveUserSignInLogs",
      "ServicePrincipalSignInLogs",
      "ManagedIdentitySignInLogs",
      "ProvisioningLogs",
      "ADFSSignInLogs",
      "RiskyUsers",
      "UserRiskEvents",
      "RiskyServicePrincipals",
      "ServicePrincipalRiskEvents",
      "MicrosoftGraphActivityLogs",
      "NetworkAccessTrafficLogs",
      "EnrichedOffice365AuditLogs",
      "RemoteNetworkHealthLogs",
      "B2CRequestLogs",
    ], c)])
    error_message = "log_categories contains a category that Entra ID diagnostic settings do not support."
  }
}

variable "archive_storage_account_id" {
  type        = string
  description = "Optional immutable storage account for long-term retention beyond the workspace."
  default     = null
}
