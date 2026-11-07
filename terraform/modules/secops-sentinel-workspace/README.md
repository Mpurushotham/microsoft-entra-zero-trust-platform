# secops-sentinel-workspace

Log Analytics workspace onboarded to Microsoft Sentinel, plus the Microsoft first-party data connectors.

- `azurerm_log_analytics_workspace` (PerGB2018, 90-day retention default, local authentication disabled)
- `azurerm_sentinel_log_analytics_workspace_onboarding`
- Data connectors, each behind a toggle in `data_connectors`:

| Key | Connector | Default | Licence |
|---|---|---|---|
| `entra_id_protection` | Microsoft Entra ID Protection alerts (`AzureActiveDirectory` kind) | on | Entra ID P2 |
| `defender_xdr` | Microsoft Defender XDR incidents and alerts (`MicrosoftThreatProtection`) | on | Microsoft 365 E5 / Defender suite |
| `office_365` | Exchange, SharePoint, Teams activity | on | Microsoft 365 |
| `threat_intelligence` | Microsoft Defender Threat Intelligence feed | on | none |
| `defender_for_identity` | Defender for Identity alerts (legacy, per product) | off | MDI |
| `defender_for_cloud_apps` | Defender for Cloud Apps alerts and discovery | off | MDCA |
| `defender_for_endpoint` | Defender for Endpoint alerts (legacy, per product) | off | MDE |

The Defender XDR connector already brings Defender for Identity, Endpoint, Office 365 and Cloud Apps alerts as
incidents. Turning on the per-product connectors as well duplicates alerts.

Entra ID sign-in and audit logs come from the `secops-entra-diagnostics` module, not from a connector.

## Inputs

`name`, `resource_group_name`, `location`, `tenant_id` (required); `retention_in_days` (90), `daily_quota_gb` (-1),
`data_connectors` (`{}`), `threat_intelligence_lookback_date`, `tags`.

## Outputs

`workspace_id` (resource ID, resolved after onboarding so dependants wait for Sentinel), `workspace_name`,
`workspace_customer_id`, `enabled_connectors`.
