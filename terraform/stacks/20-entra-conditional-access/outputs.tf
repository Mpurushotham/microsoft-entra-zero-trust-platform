output "policies" {
  description = "Object ID, display name and state per policy number."
  value       = module.conditional_access.policies
}
