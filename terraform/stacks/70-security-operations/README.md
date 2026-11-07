# 70-security-operations

Security operations layer of the Microsoft Cybersecurity Reference Architecture: Microsoft Sentinel as SIEM/SOAR
fed by Entra ID, Entra ID Protection and Microsoft Defender XDR.

| Module | Delivers |
|---|---|
| `secops-sentinel-workspace` | Log Analytics workspace, Sentinel onboarding, data connectors (Entra ID Protection, Defender XDR, Office 365, Threat Intelligence; MDI/MDCA/MDE optional) |
| `secops-entra-diagnostics` | Entra ID diagnostic setting: sign-in (interactive, non-interactive, service principal, managed identity), audit, provisioning, risk and Graph activity logs |
| `secops-sentinel-analytics` | Break-glass watchlist and six identity analytics rules (break-glass sign-in, CA change outside the pipeline, off-hours PIM activation, MFA fatigue, legacy auth success, federation change) |

Deploy it straight after bootstrap so identity changes made by later stacks are already logged.

## Prerequisites

- Stack 00 applied: `<prefix>-<env>-secops-rg` exists, providers registered, apply identity holds Log Analytics
  Contributor, Microsoft Sentinel Contributor and Entra Security Administrator.
- Licences: Entra ID P2 for risk logs and Identity Protection alerts; Microsoft 365 E5 (or Defender suite) for the
  Defender XDR connector. Switch connectors off in tfvars when not licensed.
- Defender XDR connector: turn on incident integration in the Defender portal if the workspace is not yet onboarded
  to the unified security operations platform.

## Inputs (tfvars)

`environment`, `break_glass_upns` (required); `name_prefix`, `resource_group_name`, `retention_in_days`,
`daily_quota_gb`, `entra_log_categories`, `data_connectors`, `business_hours`, `mfa_fatigue_threshold`,
`disabled_rules`, `tags`.

## Outputs

`log_analytics_workspace_id`, `log_analytics_workspace_name`, `enabled_connectors`, `entra_log_categories`,
`analytics_rule_ids`.
