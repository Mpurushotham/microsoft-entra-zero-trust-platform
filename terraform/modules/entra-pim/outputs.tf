output "role_eligibility_ids" {
  value = { for k, r in azuread_directory_role_eligibility_schedule_request.this : k => r.id }
}

output "role_assignment_ids" {
  value = { for k, r in azuread_directory_role_assignment.this : k => r.id }
}

output "group_policy_ids" {
  value = { for k, p in azuread_group_role_management_policy.member : k => p.id }
}

output "directory_role_policy_ids" {
  value = { for k, d in data.msgraph_resource.role_policy_assignment : k => d.output.policy_id }
}
