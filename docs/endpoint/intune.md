# Intune foundation

Stack: `terraform/stacks/50-intune-foundation` · Workflow: `50-intune-foundation.yml`

The foundation follows the order of Microsoft's Intune deployment guide: set up the tenant, protect access with compliance and Conditional Access, configure devices, then protect data with app protection.

## Rollout sequence

{% stepper %}
{% step %}
### Tenant setup

MDM authority is Intune, with the MDM user scope set to `zt-<env>-users-intune` (a one-time portal step). Enrolment restrictions block personal Windows and macOS enrolment and Android device administrator, and set device limits. Device categories help route devices to the right policies.
{% endstep %}

{% step %}
### RBAC and scope tags

Four built-in Intune roles are assigned to the `zt-<env>-intune-role-{helpdesk,endpoint-security,policy-profile,read-only}` groups and scoped with the `zt-<env>-corporate` scope tag. Intune Administrator itself is held by `pim-intune-administrators` and activated just in time.
{% endstep %}

{% step %}
### Compliance

Compliance policies per platform define what "healthy" means. See [Compliance and Conditional Access](compliance.md).
{% endstep %}

{% step %}
### Configuration and security baselines

Settings catalog profiles apply Credential Guard and virtualisation-based security and OS hardening. Pilot and broad Windows Update for Business rings, with the pilot ring assigned to `zt-<env>-devices-windows-ring-pilot`, and a feature update profile pinned to `feature_update_version`.
{% endstep %}

{% step %}
### Endpoint security

Defender Antivirus, firewall, attack surface reduction (audit first, then block through `asr_rule_overrides`), BitLocker and Windows LAPS. EDR onboarding is created once the Defender for Endpoint connector is enabled and `defender_for_endpoint_connected = true`.
{% endstep %}

{% step %}
### App protection

iOS and Android app protection policies follow the data protection framework, level 2 (enterprise enhanced protection) by default and set by `app_protection_level`.
{% endstep %}
{% endstepper %}

## Policy families

{% tabs %}
{% tab title="Windows" %}
| Family | Content |
|---|---|
| Compliance | BitLocker, Secure Boot, code integrity, TPM, minimum OS build, Defender antimalware, machine risk score at or below *Low* |
| Security baseline | Microsoft *Security Baseline for Windows*, assigned in the portal under Endpoint security > Security baselines |
| Settings catalog | Credential Guard and VBS, OS hardening that the baseline leaves unset |
| Updates | Update rings: pilot, broad, critical; feature update target version |
| Endpoint security | Microsoft Defender Antivirus, Windows Firewall, ASR rules in audit then block, BitLocker, Windows LAPS, EDR onboarding |
{% endtab %}

{% tab title="macOS" %}
| Family | Content |
|---|---|
| Compliance | FileVault, system integrity protection, firewall, minimum OS version |
| Settings catalog | FileVault escrow, password policy, software update |
| Endpoint security | Defender for Endpoint antivirus and EDR |
{% endtab %}

{% tab title="iOS / iPadOS" %}
| Family | Content |
|---|---|
| Compliance | Jailbreak detection, minimum OS, passcode, device threat level |
| App protection | Data protection framework level 2 or 3 |
| Enrolment | Automated Device Enrollment for corporate devices |
{% endtab %}

{% tab title="Android" %}
| Family | Content |
|---|---|
| Compliance | Play Integrity verdict, minimum OS, passcode, device threat level |
| App protection | Data protection framework level 2 or 3 |
| Enrolment | Android Enterprise fully managed, corporate-owned work profile, zero-touch |
{% endtab %}
{% endtabs %}

## Implementation notes

* Intune resources have no typed Terraform resources in `azuread`; the stack uses `msgraph_resource` against Microsoft Graph device management endpoints. Many of these endpoints are only available in Graph `beta`; each usage is noted beside the resource.
* The stack creates its own groups: dynamic device groups `zt-<env>-devices-{windows-corporate,macos,ios,android-corporate,android-work-profile}`, the assigned `zt-<env>-devices-windows-ring-pilot`, `zt-<env>-users-intune` (set as the MDM user scope in the portal) and the `zt-<env>-intune-role-*` groups. User-targeted policies can also use `persona-internals` from `10-entra-foundation`.
* A scope tag `zt-<env>-corporate` is applied automatically to corporate Windows devices.
* All Intune objects use Graph `beta`; each module's README explains why.
* ASR rules start in audit mode and are moved to block per rule after reviewing Defender for Endpoint reports.

{% hint style="info" %}
Security baselines and settings catalog can configure the same setting. Where both apply, Intune reports a conflict and neither value is guaranteed. The settings catalog profiles only add controls that the baseline leaves unset or that are tuned per environment.
{% endhint %}

## References

* [Intune deployment guide](https://learn.microsoft.com/en-us/intune/fundamentals/setup-migration)
* [Intune planning guide](https://learn.microsoft.com/en-us/intune/fundamentals/planning-guide)
* [Security baselines in Intune](https://learn.microsoft.com/en-us/intune/device-security/security-baselines/overview)
* [Endpoint security policies](https://learn.microsoft.com/en-us/intune/device-security/endpoint-security-policies)
* [App protection policies overview](https://learn.microsoft.com/en-us/intune/app-management/protection/overview)
* [App protection data protection framework](https://learn.microsoft.com/en-us/intune/app-management/protection/data-protection-framework)
* [Windows LAPS overview](https://learn.microsoft.com/en-us/windows-server/identity/laps/laps-overview)
* [Microsoft Defender for Endpoint](https://learn.microsoft.com/en-us/defender-endpoint/microsoft-defender-endpoint)
