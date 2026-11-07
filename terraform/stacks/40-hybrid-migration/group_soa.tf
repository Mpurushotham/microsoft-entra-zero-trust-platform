# Group source-of-authority conversion is exposed on the Graph beta endpoint only.
resource "msgraph_update_resource" "group_cloud_managed" {
  for_each = var.cloud_managed_group_ids

  url         = "groups/${each.key}/onPremisesSyncBehavior"
  api_version = "beta"
  body = {
    isCloudManaged = true
  }
}
