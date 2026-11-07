# intune-endpoint-security

Endpoint security policies built on Intune's endpoint security templates. Each one is a `configurationPolicies` object bound to a template through `templateReference`, so it shows up under **Endpoint security** in the admin center.

| Key | Template | Template ID | Highlights |
|---|---|---|---|
| `antivirus` | Microsoft Defender Antivirus | `804339ad-1553-4478-a742-138fb5807418_1` | Real-time, behaviour, IOAV, script, archive and email scanning; cloud protection with configurable block level; PUA block; network protection; local admin merge disabled |
| `firewall` | Windows Firewall | `6078910e-d808-4a9f-a51d-1b8a7bacb7c0_1` | All profiles on, inbound block, outbound allow, notifications off, public-profile local rule merge configurable |
| `asr` | Attack Surface Reduction Rules | `e8c053d6-9f95-42b1-a7f1-ebfd71c67a4b_1` | 19 rules: the three standard protection rules block, the rest audit (override with `asr_rules`) |
| `edr` | Endpoint detection and response | `0385b795-0f2f-44ac-8602-9f65bf6adede_1` | Onboarding package from the MDE connector, sample sharing |
| `bitlocker` | BitLocker | `46ddfc50-d10f-4867-b852-9434254b3bff_1` | Silent encryption (standard users), XTS-AES 256 for OS and fixed drives, recovery key escrowed to Entra ID, rotated after use |
| `laps` | Windows LAPS | `adc46e5a-f4aa-4ff6-aeff-4f27bc525796_1` | Back up to Entra ID, age, length, complexity, post-authentication reset |

LAPS and EDR settings are template-only, meaning they're not available in the plain settings catalog. That's why the bodies carry `settingInstanceTemplateReference` and `settingValueTemplateReference` IDs. The bodies live in `templates/*.json.tftpl`.

ASR rollout follows Microsoft's guidance: run in audit, review the Defender ASR report, then move rules to `block` with `asr_rules` overrides.

## Prerequisites

- **EDR:** the Microsoft Defender for Endpoint connector is enabled in Intune (Endpoint security > Microsoft Defender for Endpoint).
- **LAPS:** "Enable Microsoft Entra Local Administrator Password Solution" is turned on in Entra ID > Devices > Device settings. Stack 10-entra-foundation owns this tenant setting.

**API version:** `beta`, because `templateReference` exists only there. Updates use `PUT`.

## Inputs

`name_prefix`, `environment`, `role_scope_tag_ids`, `policies`, `antivirus` (object), `firewall_public_allow_local_rule_merge`, `asr_rules` (map of rule => off|audit|warn|block), `bitlocker` (object of drive methods), `laps` (object), `assignments`.

## Outputs

`policy_ids`, `asr_rule_modes`
