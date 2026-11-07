output "workflow_ids" {
  value = { for k, w in msgraph_resource.workflow : k => w.id }
}
