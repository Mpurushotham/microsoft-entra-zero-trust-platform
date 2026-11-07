output "exclusion_group_object_id" {
  value = azuread_group.exclusion.object_id
}

output "exclusion_group_display_name" {
  value = azuread_group.exclusion.display_name
}

output "accounts" {
  description = "UPN and object ID per alias. Consumed by monitoring (sign-in alert rule) and access reviews."
  value = {
    for k, u in azuread_user.this : k => {
      user_principal_name = u.user_principal_name
      object_id           = u.object_id
    }
  }
}

output "initial_passwords" {
  description = "Initial passwords, for one-time hand-off into the sealed credential store. Read with `terraform output -json initial_passwords` on a trusted workstation only."
  value       = { for k, p in random_password.this : k => p.result }
  sensitive   = true
}

output "sign_in_alert_kql" {
  description = "KQL for a Log Analytics / Sentinel alert on any emergency account sign-in."
  value       = <<-KQL
    SigninLogs
    | where UserId in (${join(", ", [for u in azuread_user.this : "\"${u.object_id}\""])})
    | project TimeGenerated, UserPrincipalName, IPAddress, Location, AppDisplayName, ResultType, ConditionalAccessStatus
  KQL
}
