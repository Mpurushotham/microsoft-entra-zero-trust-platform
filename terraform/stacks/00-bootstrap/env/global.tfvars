name_prefix  = "zt"
location     = "westeurope"
environments = ["dev", "prod"]

github_repository     = "Mpurushotham/microsoft-entra-zero-trust-platform"
github_default_branch = "main"

# Replace with the object IDs of the platform owners (az ad signed-in-user show --query id -o tsv).
operator_object_ids = ["00000000-0000-0000-0000-000000000000"]

state_resource_group_name    = "zt-tfstate-rg"
state_storage_account_name   = "zttfstatecontoso001"
state_replication_type       = "GZRS"
state_public_network_access  = "Enabled"
state_network_default_action = "Allow"
state_allowed_ip_ranges      = []

# Fill in after stack 70 is applied to send state access logs to Microsoft Sentinel.
state_log_analytics_workspace_id = null

tags = {
  owner       = "platform-identity"
  cost-center = "security"
}
