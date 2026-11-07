# bootstrap-state-storage

Storage account and container that hold Terraform state for every platform stack.

Hardening applied:

| Control | Setting |
|---|---|
| Authentication | `shared_access_key_enabled = false`, `default_to_oauth_authentication = true`: Entra ID and RBAC only, no keys or SAS |
| Public access | `allow_nested_items_to_be_public = false`, private container |
| Transport | TLS 1.2 minimum, HTTPS only |
| Encryption | Infrastructure (double) encryption with Microsoft-managed keys |
| Recovery | Blob versioning, change feed, blob and container soft delete (30 days default), `CanNotDelete` lock, `prevent_destroy` |
| Exfiltration | `allowed_copy_scope = "AAD"`, cross-tenant replication off, local users and SFTP off |
| Logging | Optional blob diagnostic setting to the Sentinel workspace (`log_analytics_workspace_id`) |

## Network

GitHub-hosted runners use changing public IPs, so the default is `public_network_access = "Enabled"` with
`network_default_action = "Allow"`. Data-plane access still needs an Entra ID token and a Storage Blob Data role.
For a private posture, set `public_network_access = "Disabled"`, add a private endpoint, and run the
workflows on self-hosted runners inside the virtual network. `Deny` with `allowed_ip_ranges` suits fixed egress IPs.

## Inputs

| Name | Type | Default |
|---|---|---|
| `resource_group_name` | string | required |
| `location` | string | required |
| `storage_account_name` | string | required, globally unique |
| `container_name` | string | `tfstate` |
| `replication_type` | string | `ZRS` |
| `soft_delete_retention_days` | number | `30` |
| `public_network_access` | string | `Enabled` |
| `network_default_action` | string | `Allow` |
| `allowed_ip_ranges` | set(string) | `[]` |
| `log_analytics_workspace_id` | string | `null` |
| `delete_lock_enabled` | bool | `true` |
| `tags` | map(string) | `{}` |

## Outputs

`storage_account_id`, `storage_account_name`, `container_name`, `container_scope` (ARM scope for data-plane RBAC).

## Example

```hcl
module "state_storage" {
  source               = "../../modules/bootstrap-state-storage"
  resource_group_name  = "zt-tfstate-rg"
  location             = "westeurope"
  storage_account_name = "zttfstatecontoso001"
  replication_type     = "GZRS"
}
```
