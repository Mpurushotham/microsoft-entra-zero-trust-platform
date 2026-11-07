# secops-sentinel-analytics

Identity-focused Microsoft Sentinel scheduled analytics rules and the break-glass watchlist. Queries live in
`templates/` as KQL so they can be tested in Log Analytics as-is (fill `${...}` placeholders by hand).

| Key | Rule | Severity | Frequency / period | MITRE ATT&CK |
|---|---|---|---|---|
| `break-glass-sign-in` | Any sign-in attempt by an account in the `BreakGlassAccounts` watchlist | High (success) / Medium | 5m / 5m | T1078 |
| `conditional-access-change` | CA policy added, updated or deleted by anyone except the pipeline identities; deletes always alert | Medium / High (delete) | 15m / 15m | T1562, T1556 |
| `pim-activation-outside-hours` | PIM role or PIM for Groups activation outside `business_hours` | Medium / High (tier-0 role) | 1h / 1h | T1078, T1098 |
| `mfa-fatigue` | At least `mfa_fatigue_threshold` denied, unanswered or fraud-reported MFA prompts in an hour | Medium / High (success after prompts or fraud report) | 15m / 1h | T1621 |
| `legacy-auth-success` | Successful sign-in over a legacy protocol | Medium / High (CA not applied) | 1h / 1h | T1078 |
| `federated-domain-change` | Domain federated, federation settings changed or a domain verified | High | 15m / 15m | T1484 |

Every query returns `AccountUpn`, `IPAddress` and `AlertSeverity`; the rules map Account and IP entities, take the
severity from `AlertSeverity`, and group incidents by account over five hours.

## Inputs

| Name | Type | Default |
|---|---|---|
| `log_analytics_workspace_id` | string | required (use the onboarding output) |
| `name_prefix` | string | `zt` |
| `break_glass_upns` | set(string) | required |
| `trusted_automation_names` | set(string) | `[]` |
| `business_hours` | object | 07:00-19:00 UTC, Monday to Friday |
| `mfa_fatigue_threshold` | number | `5` |
| `disabled_rules` | set(string) | `[]` |

## Outputs

`rule_ids`, `watchlist_alias`.
