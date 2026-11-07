# intune-update-rings

Windows Update for Business rings (`windowsUpdateForBusinessConfiguration`) plus feature update profiles (`windowsFeatureUpdateProfiles`).

The pattern follows the Intune deployment guide:

- A **pilot** ring with zero deferral and short deadlines.
- A **broad** ring that excludes the pilot group.
- Feature updates pinned by a feature update profile, so a new Windows release only reaches devices when `feature_update_version` changes.

Rings install at the maintenance time outside active hours. They block user pause, keep Microsoft Update for other products, and allow Windows 11 upgrade.

**API version:** `beta`. `roleScopeTagIds` is beta-only on rings, and feature update profiles are beta-only.

## Inputs

`name_prefix`, `environment`, `role_scope_tag_ids`, `rings` (map of deferral/deadline/grace values with include/exclude group IDs), `active_hours`, `feature_update_profiles` (map of version string such as `Windows 11, version 25H2` with include/exclude group IDs).

## Outputs

`ring_ids`, `feature_update_profile_ids`
