# intune-configuration

Settings catalog profiles for Windows that sit alongside the Microsoft security baseline:

| Key | Settings |
|---|---|
| `credential_guard` | VBS enabled, platform security level (Secure Boot, optionally DMA), Credential Guard with or without UEFI lock |
| `os_hardening` | SmartScreen in shell with no override, Kernel DMA Protection enumeration policy, blank-password local accounts limited to console, Wi-Fi Sense auto-connect off |

All settings are choice settings. They render through one generic template (`templates/settings-catalog.json.tftpl`) from a `definitionId => option` map in `locals.catalog`. To add a setting, add a line to that map. Look up the definition ID and option suffix in the settings catalog (Graph: `deviceManagement/configurationSettings`).

You still deploy the Microsoft-published *Security Baseline for Windows* from Endpoint security > Security baselines. These profiles only add the controls that baseline leaves unset or that we tune per environment.

**API version:** `beta`, because `configurationPolicies` is beta-only. Updates use `PUT`, because Intune replaces the `settings` navigation property as a whole.

## Inputs

`name_prefix`, `environment`, `role_scope_tag_ids`, `policies` (set), `credential_guard_uefi_lock` (bool, default true), `vbs_require_dma_protection` (bool, default false), `dma_guard_policy` (`block_all`/`after_login`/`allow_all`), `assignments`.

## Outputs

`policy_ids`
