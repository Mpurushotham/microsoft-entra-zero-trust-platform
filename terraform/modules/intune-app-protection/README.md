# intune-app-protection

iOS/iPadOS and Android app protection (MAM) policies that implement the Microsoft *App protection policy data protection framework*. `protection_level` selects the level, and each level inherits the one below it (`locals.level_1..3`).

| Control | Level 1 basic | Level 2 enhanced (default) | Level 3 high |
|---|---|---|---|
| Backup | allowed | blocked | blocked |
| Send org data | all apps | policy-managed apps | policy-managed apps |
| Receive data | all apps | all apps | policy-managed apps |
| Cut/copy/paste | any app | managed with paste-in | managed with paste-in |
| Save copies | allowed | OneDrive / SharePoint only | OneDrive / SharePoint only |
| Print | allowed | blocked | blocked |
| Open links | any | Microsoft Edge | Microsoft Edge |
| Screen capture (Android) / 3rd-party keyboards (iOS) | allowed | blocked | blocked |
| PIN | 4 digits, simple allowed | 4 digits | 6 digits, simple blocked, required even with device PIN |
| Notifications | allow | allow | block org data |
| Device threat level | n/a | n/a | secured (needs an MTD connector) |

All levels enforce encryption, offline access checks (720 minutes), wipe after 90 days offline, jailbreak/root block and a minimum OS. Targeted apps are the core Microsoft 365 apps (Outlook, Teams, Word, Excel, PowerPoint, Microsoft 365, OneDrive, SharePoint, Edge, OneNote), set through the `targetApps` action. Policies are assigned to **user** groups. Pair them with the Conditional Access "Require app protection policy" grant from stack 20.

**API version:** `beta`, because `roleScopeTagIds` and several level 2/3 controls are beta-only.

## Inputs

`name_prefix`, `environment`, `role_scope_tag_ids`, `protection_level` (1-3), `platforms`, `ios_bundle_ids`, `android_package_ids`, `minimum_os_versions`, `include_group_ids` (required), `exclude_group_ids`.

## Outputs

`policy_ids`, `protection_level`
