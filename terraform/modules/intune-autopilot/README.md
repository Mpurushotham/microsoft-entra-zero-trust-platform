# intune-autopilot

Zero-touch provisioning objects:

- **Windows Autopilot deployment profiles** (`azureADWindowsAutopilotDeploymentProfile`). Every profile uses Microsoft Entra join, which is Microsoft's recommended join type for new devices.
  - `user_driven`: single user, standard user rights.
  - `user_driven` with `allow_preprovisioning = true`: the technician flow (formerly white glove).
  - `self_deploying`: shared device, no user affinity, requires TPM 2.0 attestation.
- **Profile assignments** to the group-tag device groups. Each assignment is a `msgraph_resource` on `.../assignments`.
- **Enrollment Status Page** (`windows10EnrollmentCompletionPageConfiguration`). It tracks the required apps as blocking, applies to Autopilot only, and installs quality updates during OOBE.
- **Required Microsoft Store apps** (`winGetApp`, Company Portal by default), assigned as required to the Autopilot device group.
- **Android Enterprise zero-touch**, optional. Creates the corporate-owned fully managed enrollment profile and outputs the DPC extras JSON for the zero-touch portal.
- **Apple ADE**, optional. Creates a supervised, user-affinity enrollment profile with Setup Assistant modern authentication, under an Apple Business Manager token that has already been uploaded.

Some steps can't be done through Graph and stay as manual runbook steps (see `scripts/intune/README.md`):

- Uploading the ABM token.
- Binding Managed Google Play.
- Creating an Autopilot device preparation policy. Its schema isn't published, so you create it in the admin center against the group from stack 60.

**API version:** `beta` throughout. Autopilot profiles, `winGetApp`, ESP app tracking, Android device owner profiles and ADE profiles are beta-only.

## Inputs

`name_prefix`, `environment`, `role_scope_tag_ids`, `deployment_profiles` (map), `enrollment_status_page` (object), `required_store_apps` (map), `required_app_group_ids`, `android_zero_touch` (object), `apple_ade` (object).

## Outputs

`deployment_profile_ids`, `enrollment_status_page_id`, `store_app_ids`, `android_fully_managed_profile_id`, `apple_ade_profile_id`, `android_zero_touch_dpc_extras`
