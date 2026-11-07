# Licensing matrix

Licensing changes over time. Confirm against the Microsoft Learn licensing pages and the current Microsoft 365 service descriptions before purchase. This matrix reflects the features the platform configures.

## Suites

| Suite | Entra ID | Intune | Defender | Notes |
|---|---|---|---|---|
| Microsoft 365 E3 | P1 | Plan 1 | Defender for Endpoint P1 | Covers stacks 10, 20 (non-risk policies), 40, 50, 60 |
| Microsoft 365 E5 | P2 | Plan 1 | Defender for Endpoint P2, Identity, Office 365 P2, Cloud Apps | Covers every stack except lifecycle workflows |
| EMS E3 | P1 | Plan 1 | – | Identity and endpoint without Office apps |
| EMS E5 | P2 | Plan 1 | Defender for Identity, Cloud Apps | |
| Microsoft Entra ID Governance | Add-on to P1 or P2 | – | – | Lifecycle workflows and advanced governance |
| Microsoft Entra Workload ID Premium | Add-on | – | – | Conditional Access and risk for workload identities |

## Feature matrix

| Feature | Free | P1 | P2 | ID Governance | Intune Plan 1 | Stack |
|---|---|---|---|---|---|---|
| Emergency access accounts, groups | ✓ | ✓ | ✓ | ✓ | | 10 |
| Dynamic groups | | ✓ | ✓ | ✓ | | 10 |
| Administrative units | ✓ | ✓ | ✓ | ✓ | | 10 |
| Restricted management administrative units, dynamic AU membership | | ✓ | ✓ | ✓ | | 10 |
| Authentication methods policy, passkeys, TAP | ✓ | ✓ | ✓ | ✓ | | 10 |
| Custom security attributes | ✓ | ✓ | ✓ | ✓ | | 10 |
| Company branding | | ✓ | ✓ | ✓ | | 10 |
| Conditional Access | | ✓ | ✓ | ✓ | | 20 |
| Authentication strengths in Conditional Access | | ✓ | ✓ | ✓ | | 20 |
| Risk-based Conditional Access, ID Protection | | | ✓ | | | 20 |
| Token protection | | ✓ | ✓ | ✓ | | 20 |
| Privileged Identity Management, PIM for Groups | | | ✓ | ✓ | | 30 |
| Entitlement management (core) | | | ✓ | ✓ | | 30 |
| Access reviews | | | ✓ | ✓ | | 30 |
| Lifecycle workflows | | | | ✓ | | 30 |
| Cloud Sync, password hash sync | ✓ | ✓ | ✓ | ✓ | | 40 |
| Cloud Sync group writeback | | ✓ | ✓ | ✓ | | 40 |
| Staged rollout | ✓ | ✓ | ✓ | ✓ | | 40 |
| Enterprise application SSO | ✓ | ✓ | ✓ | ✓ | | 40 |
| Intune MDM, compliance, configuration, baselines | | | | | ✓ | 50 |
| App protection policies | | | | | ✓ | 50 |
| Windows Autopilot, device preparation | | ✓ | | | ✓ | 60 |
| Entra diagnostic settings for sign-in logs | | ✓ | ✓ | ✓ | | 70 |
| Risk log export | | | ✓ | | | 70 |

{% hint style="info" %}
Microsoft Sentinel and Log Analytics are billed on Azure consumption. Microsoft 365 E5 customers receive a data grant for some Microsoft 365 data sources; check the current offer when sizing the workspace.
{% endhint %}

{% hint style="warning" %}
Licensing is per user who benefits from the feature. For example, every user in scope of a risk-based policy needs P2, and every eligible or approving user in PIM needs P2 or ID Governance.
{% endhint %}

## References

* [Microsoft Entra licensing](https://learn.microsoft.com/en-us/entra/fundamentals/licensing)
* [Microsoft Entra ID Governance licensing fundamentals](https://learn.microsoft.com/en-us/entra/id-governance/licensing-fundamentals)
* [Microsoft Intune licensing](https://learn.microsoft.com/en-us/intune/fundamentals/licensing)
* [Windows Autopilot requirements](https://learn.microsoft.com/en-us/autopilot/requirements)
