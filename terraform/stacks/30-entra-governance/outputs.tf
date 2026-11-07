output "access_packages" {
  value = module.entitlement_management.access_packages
}

output "access_review_definition_ids" {
  value = module.access_reviews.review_definition_ids
}

output "lifecycle_workflow_ids" {
  value = module.lifecycle_workflows.workflow_ids
}

output "directory_role_policy_ids" {
  value = module.pim.directory_role_policy_ids
}
