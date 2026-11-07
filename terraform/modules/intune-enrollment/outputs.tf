output "platform_restriction_ids" {
  value = { for k, r in msgraph_resource.platform_restriction : k => r.id }
}

output "device_limit_id" {
  value = msgraph_resource.device_limit.id
}

output "device_category_ids" {
  value = { for k, c in msgraph_resource.device_category : k => c.id }
}
