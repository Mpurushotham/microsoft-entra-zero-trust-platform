# hybrid-staged-rollout

Creates the migration wave groups and the Microsoft Entra **staged rollout** policies
(`policies/featureRolloutPolicies`) used to move users from federated (AD FS) sign-in to
cloud authentication one wave at a time, before the domain itself is converted to managed.

## How it works

- One assigned, security-enabled group per wave (`<prefix>-<env>-hybrid-wave-<wave>`).
  Staged rollout ignores dynamic and nested groups, so neither is used.
- One feature rollout policy per entry in `staged_features`, `isAppliedToOrganization = false`.
- Each wave in `enabled_waves` is attached to every policy through
  `policies/featureRolloutPolicies/{id}/appliesTo/$ref`. Advancing a wave is a one-line
  tfvars change that goes through review.
- Group membership is **not** managed here. `scripts/hybrid-migration/Start-StagedRolloutWave.ps1`
  adds users in batches, because the first population of a staged-rollout group is limited to
  200 users. More users can be added after the group is attached.

## Service limits to respect

| Limit | Value |
|---|---|
| Groups per feature | 10 |
| Users when a group is first attached | 200 |
| Cloud authentication methods per user | one of PHS or PTA |

Staged rollout needs the domain to still be federated and PHS (or PTA agents) already working.
Seamless SSO must be enabled on the AD forest before staging `seamlessSso`.

## Inputs

| Name | Type | Default |
|---|---|---|
| `name_prefix` | string | `"zt"` |
| `environment` | string (`dev`/`prod`) | n/a |
| `waves` | list(string), ≤ 10 | `["pilot","wave1","wave2","all"]` |
| `enabled_waves` | list(string) | `[]` |
| `staged_features` | set(string) | `["passwordHashSync","seamlessSso"]` |
| `rollout_enabled` | bool | `true` |
| `group_owners` | set(string) | `[]` |

## Outputs

| Name | Description |
|---|---|
| `wave_groups` | wave → `{ object_id, display_name }` |
| `feature_rollout_policy_ids` | feature → policy ID |
| `enabled_waves` | waves currently attached |

## Example

```hcl
module "staged_rollout" {
  source          = "../../modules/hybrid-staged-rollout"
  environment     = "dev"
  enabled_waves   = ["pilot"]
  staged_features = ["passwordHashSync", "seamlessSso"]
}
```

Graph permission for the deploying identity: `Directory.ReadWrite.All` (feature rollout policies)
and `Group.ReadWrite.All`.
