# 60-intune-autopilot-zero-touch

Zero-touch provisioning: devices ship from the OEM or reseller already registered in Windows Autopilot with a group tag. On first boot they join Microsoft Entra ID, enroll in Intune and stay on the Enrollment Status Page until the baseline from stack 50 is in place.

## What it deploys

| Object | Name |
|---|---|
| Dynamic group, all Autopilot devices (`[ZTDId]`) | `zt-<env>-devices-autopilot-all` |
| Dynamic group per group tag (`[OrderID]:<TAG>`) | `zt-<env>-devices-autopilot-corp-win`, `-preprov`, `-kiosk` |
| Device preparation group (owner: Intune Provisioning Client) | `zt-<env>-devices-autopilot-device-preparation` |
| Autopilot profiles | `zt-<env>-autopilot-user-driven`, `-pre-provisioned`, `-self-deploying` |
| Enrollment Status Page | `zt-<env>-autopilot-esp` (priority 1, assigned to all Autopilot devices) |
| Required app | Company Portal (Microsoft Store `9WZDNCRFJ3PZ`), blocking in ESP |
| Optional | Android Enterprise fully managed profile with DPC extras output; Apple ADE profile |

Group tag rule example:

```text
(device.devicePhysicalIds -any (_ -eq "[OrderID]:CORP-WIN"))
```

## Windows Autopilot vs Autopilot device preparation

Windows Autopilot (profiles above) depends on hardware hash registration and fits OEM/reseller zero-touch.

Autopilot device preparation needs no pre-registration, adds the device to the device preparation group during OOBE and delivers the apps and scripts you select. It suits devices that can't be pre-registered and Windows 365. Graph doesn't publish its policy schema yet. To use it:

1. In the Intune admin center, go to Devices > Enrollment > Device preparation policies and create a policy.
2. Select `zt-<env>-devices-autopilot-device-preparation` as the device group.
3. Pick the user group and the apps.
4. Microsoft recommends corporate identifiers when you also block personal Windows enrollment (stack 50 does).

If the Intune Provisioning Client service principal is missing, create it once with `New-MgServicePrincipal -AppId f1346770-5b25-470b-88bd-d5744ab7952c`.

## Apple ADE and Android Enterprise zero-touch

**Apple ADE:**

1. Upload the Apple Business Manager token (Devices > Enrollment > Apple > Enrollment program tokens).
2. Set `apple_dep_onboarding_setting_id`.
3. Assign the profile to devices in ABM/Intune.

**Android zero-touch:**

1. Bind Managed Google Play.
2. Set `android_zero_touch_enabled = true`.
3. Copy the token from the fully managed profile in the admin center into the `android_zero_touch_dpc_extras` output.
4. Paste the resulting JSON into the zero-touch portal configuration.

## Deploy

Use the same backend flags as stack 50 with `key=60-intune-autopilot-zero-touch/<env>.tfstate`, then:

```bash
terraform plan -var-file=env/dev.tfvars
```

To register existing hardware, use `scripts/intune/Import-AutopilotDevices.ps1` with the group tag from the `group_tags` output.
