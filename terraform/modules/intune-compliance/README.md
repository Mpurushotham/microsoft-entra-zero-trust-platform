# intune-compliance

Device compliance policies for Windows, macOS, iOS/iPadOS and Android Enterprise (corporate-owned and personally owned work profile), following the Microsoft Zero Trust guidance that compliance feeds Conditional Access ("Require device to be marked as compliant").

| Platform key | Graph type | Main controls |
|---|---|---|
| `windows` | `windows10CompliancePolicy` | BitLocker, Secure Boot, code integrity, TPM, firewall, Defender AV/real-time, signatures current, minimum OS, optional MDE risk |
| `macos` | `macOSCompliancePolicy` | Password, FileVault, SIP, firewall, Gatekeeper |
| `ios` | `iosCompliancePolicy` | Passcode, jailbreak block, minimum OS |
| `android_fully_managed` | `androidDeviceOwnerCompliancePolicy` | Password, encryption, Play Integrity, minimum OS |
| `android_work_profile` | `androidWorkProfileCompliancePolicy` | Password complexity, encryption, Play Integrity, Company Portal integrity |

Windows password rules are not set; Windows Hello for Business covers sign-in.

Bodies live in `templates/<platform>.json.tftpl`. Each policy has a single scheduled action: mark noncompliant (block) after `noncompliance_grace_period_hours`. Assignments go through the `assign` action (`msgraph_resource_action`), which replaces all assignments of the policy on each apply.

**API version:** `beta`, because `roleScopeTagIds` is beta-only.

**Behaviour to know:** `scheduledActionsForRule` is only accepted on create, and GET doesn't return it. To change the grace period on an existing policy, replace the policy (`terraform apply -replace`).

## Inputs

| Name | Type | Default |
|---|---|---|
| `name_prefix` | string | `zt` |
| `environment` | string (`dev`/`prod`) | required |
| `role_scope_tag_ids` | list(string) | `["0"]` |
| `platforms` | set(string) | all five |
| `os_minimum_versions` | map(string) | Windows 10.0.26100.0, macOS 14.0, iOS 17.0, Android 13.0/12.0 |
| `noncompliance_grace_period_hours` | number | `24` |
| `device_threat_protection` | object({enabled, level}) | disabled, `medium` |
| `assignments` | map(object({include_group_ids, exclude_group_ids})) | `{}` |

## Outputs

`policy_ids`, `policy_names`

## Example

```hcl
module "compliance" {
  source      = "../../modules/intune-compliance"
  environment = "dev"
  assignments = {
    windows = { include_group_ids = [azuread_group.windows.object_id] }
  }
}
```
