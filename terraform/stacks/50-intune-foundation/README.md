# 50-intune-foundation

The Intune baseline for the endpoint pillar of Zero Trust: verify device health explicitly, then let Conditional Access act on compliance.

## What it deploys

| Area | Module | Objects |
|---|---|---|
| Groups | (stack) | Dynamic device groups `zt-<env>-devices-{windows-corporate,macos,ios,android-corporate,android-work-profile}`, assigned `zt-<env>-devices-windows-ring-pilot`, `zt-<env>-users-intune`, Intune role groups `zt-<env>-intune-role-{helpdesk,endpoint-security,policy-profile,read-only}` |
| RBAC | `intune-rbac` | Scope tag `zt-<env>-corporate` (auto-tags corporate Windows devices), four built-in role assignments |
| Enrollment | `intune-enrollment` | Per-platform restrictions (block personal Windows/macOS, block Android device administrator), device limit, device categories |
| Compliance | `intune-compliance` | Windows, macOS, iOS, Android fully managed, Android work profile |
| Configuration | `intune-configuration` | Credential Guard / VBS, OS hardening (settings catalog) |
| Endpoint security | `intune-endpoint-security` | Defender AV, firewall, ASR, EDR (once MDE is connected), BitLocker, Windows LAPS |
| Updates | `intune-update-rings` | Pilot and broad WUfB rings, feature update profile pinned to `feature_update_version` |
| MAM | `intune-app-protection` | iOS and Android app protection, framework level 2 by default |

All Intune objects use Graph `beta`; see each module's README for the reason.

## Prerequisites

1. Intune licences (Microsoft 365 E3/E5 or EMS) for the users in `zt-<env>-users-intune`.
2. The pipeline identity holds these Graph application permissions:
   - `DeviceManagementConfiguration.ReadWrite.All`
   - `DeviceManagementApps.ReadWrite.All`
   - `DeviceManagementServiceConfig.ReadWrite.All`
   - `DeviceManagementRBAC.ReadWrite.All`
   - `Group.ReadWrite.All`
   - `Directory.Read.All`
3. One-time portal steps with no supported API:
   - Entra ID > Mobility (MDM and WIP) > Microsoft Intune: set **MDM user scope** to `zt-<env>-users-intune`.
   - Enable the Microsoft Defender for Endpoint connector, then set `defender_for_endpoint_connected = true`.
   - Make sure **Microsoft Entra LAPS** is enabled in device settings (owned by 10-entra-foundation).

## Rollout order

The order follows the Intune deployment guide:

1. Apply to `dev` and enroll pilot devices.
2. Add pilot devices to `zt-<env>-devices-windows-ring-pilot`.
3. Review the compliance and ASR audit reports.
4. Move ASR rules to block in `env/prod.tfvars`.
5. Apply to `prod`.

Turn on the Conditional Access compliant-device grant (stack 20) only after compliance reports are clean.

## Deploy

```bash
terraform init \
  -backend-config="resource_group_name=$TFSTATE_RG" \
  -backend-config="storage_account_name=$TFSTATE_SA" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=50-intune-foundation/dev.tfstate" \
  -backend-config="use_oidc=true" -backend-config="use_azuread_auth=true"
terraform plan -var-file=env/dev.tfvars
```

## Inputs

`name_prefix`, `environment`, `intune_user_group_names`, `compliance_grace_period_hours`, `defender_for_endpoint_connected`, `app_protection_level`, `asr_rule_overrides`, `update_rings`, `feature_update_version`, `device_categories`.

## Outputs

Group IDs (`device_group_ids`, `windows_ring_pilot_group_id`, `intune_users_group_id`, `intune_role_group_ids`), policy IDs per module, and `scope_tag_ids`.
