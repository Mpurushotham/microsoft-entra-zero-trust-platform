# intune-enrollment

Enrollment guard rails:

- **Per-platform enrollment restrictions** (`deviceEnrollmentPlatformRestrictionConfiguration`):
  - Personal Windows and macOS enrollment is blocked.
  - Personal iOS and Android Enterprise work profile are allowed, for BYOD with MAM.
  - Android device administrator is blocked, per Microsoft's deprecation of DA.
- **Device limit** per user (`deviceEnrollmentLimitConfiguration`).
- **Device categories** that users pick in Company Portal. You can use them in dynamic groups with `device.deviceCategory`.

Restrictions evaluate the enrolling **user**, so `restriction_group_ids` must be user groups. Priority 0 belongs to the tenant default restriction and can't be managed here. Pick priorities that don't collide with restrictions created outside Terraform.

Autopilot and Apple ADE devices are corporate-identified, so the personal-device block doesn't affect zero-touch enrollment.

You don't configure the MDM authority here. New tenants default to Intune. Automatic MDM enrollment scope (Entra ID > Mobility (MDM and WIP) > Microsoft Intune > MDM user scope) has no supported Graph API. Set it to the Intune users group in the portal; it's a documented one-time step in the stack 50 README.

**API version:** `beta`. The per-platform restriction type is beta-only.

## Inputs

`name_prefix`, `environment`, `role_scope_tag_ids`, `platform_restrictions` (map keyed by `windows`/`ios`/`android`/`androidForWork`/`mac`), `device_limit`, `device_limit_priority`, `restriction_group_ids` (required), `device_categories`.

## Outputs

`platform_restriction_ids`, `device_limit_id`, `device_category_ids`
