# Endpoint architecture

Intune is the single management authority for corporate devices. Device health becomes an access signal through compliance, which Conditional Access consumes. New Windows devices are provisioned with Windows Autopilot and never touched by IT.

## Endpoint management planes

```mermaid
flowchart LR
    subgraph Enrol["Enrolment"]
        AP["Windows Autopilot<br/>device preparation / classic"]
        ADE["Apple Automated<br/>Device Enrollment"]
        AE["Android Enterprise<br/>zero-touch / fully managed"]
        BYOD["Personal devices<br/>MAM only"]
    end
    subgraph Intune["Microsoft Intune"]
        CMP["Compliance policies<br/>per platform"]
        CFG["Settings catalog<br/>Credential Guard, hardening,<br/>WUfB rings"]
        BL["Security baselines"]
        ES["Endpoint security<br/>AV, firewall, ASR, EDR,<br/>BitLocker, LAPS"]
        MAM["App protection policies<br/>iOS and Android"]
        RBAC["Scope tags and RBAC"]
    end
    subgraph Signals
        MDE["Defender for Endpoint<br/>machine risk"]
    end
    AP --> CMP
    ADE --> CMP
    AE --> CMP
    BYOD --> MAM
    MDE --> CMP
    CMP -- "isCompliant" --> CA["Conditional Access"]
    MAM -- "approved app + APP" --> CA
```

## Policy layering

| Layer | Windows | macOS | iOS / iPadOS | Android Enterprise |
|---|---|---|---|---|
| Enrolment | Autopilot, Entra join | ADE | ADE | Zero-touch, fully managed, work profile |
| Compliance | BitLocker, Secure Boot, TPM, OS version, Defender, machine risk | FileVault, OS version, firewall | Jailbreak, OS version, passcode | Play Integrity, OS version, passcode |
| Configuration | Settings catalog (Credential Guard, OS hardening), Update rings and feature updates | Settings catalog | Device restrictions | Device restrictions |
| Security baseline | Microsoft Security Baseline for Windows, assigned in the portal | Not applicable | Not applicable | Not applicable |
| Endpoint security | Antivirus, firewall, ASR, EDR onboarding | Antivirus, EDR | Not applicable | Not applicable |
| App protection | Not applicable | Not applicable | Data protection framework level 2 or 3 | Data protection framework level 2 or 3 |

{% hint style="info" %}
Security baselines and settings catalog profiles can overlap. The Microsoft baseline is assigned from the portal. The Terraform settings catalog profiles cover only settings the baseline leaves unset, which avoids the conflicts Intune reports as errors.
{% endhint %}

## Assignment model

Policies target Entra groups, never individual users. Intune device groups are owned by the endpoint stacks only: `50-intune-foundation` creates the platform and ring groups, and `60-intune-autopilot-zero-touch` creates the Autopilot groups. `10-entra-foundation` creates no device groups.

```mermaid
flowchart LR
    subgraph S50["50-intune-foundation"]
        G1["zt-env-devices-windows-corporate"]
        G2["zt-env-devices-macos"]
        G3["zt-env-devices-ios"]
        G4["zt-env-devices-android-corporate"]
        G5["zt-env-devices-android-work-profile"]
        G6["zt-env-devices-windows-ring-pilot<br/>assigned"]
        G7["zt-env-users-intune<br/>MDM user scope"]
    end
    subgraph S60["60-intune-autopilot-zero-touch"]
        A0["zt-env-devices-autopilot-all<br/>ZTDId rule"]
        A1["zt-env-devices-autopilot-corp-win<br/>OrderID CORP-WIN"]
        A2["zt-env-devices-autopilot-preprov<br/>OrderID PREPROV"]
        A3["zt-env-devices-autopilot-kiosk<br/>OrderID KIOSK"]
        A4["zt-env-devices-autopilot-device-preparation<br/>owner Intune Provisioning Client"]
    end
    G1 --> CMP["Compliance, baselines,<br/>endpoint security"]
    G6 --> UPD["Pilot update ring"]
    A0 --> ESP["Enrollment Status Page"]
    A1 --> P1["User-driven profile"]
    A2 --> P2["Pre-provisioned profile"]
    A3 --> P3["Self-deploying profile"]
    A4 --> DP["Device preparation policy"]
```

| Group | Owner | Membership |
|---|---|---|
| `zt-<env>-devices-{windows-corporate,macos,ios,android-corporate,android-work-profile}` | 50 | Dynamic, by platform and ownership |
| `zt-<env>-devices-windows-ring-pilot` | 50 | Assigned pilot devices for the pilot update ring |
| `zt-<env>-users-intune` | 50 | Users in MDM scope |
| `zt-<env>-intune-role-{helpdesk,endpoint-security,policy-profile,read-only}` | 50 | Intune RBAC role groups |
| `zt-<env>-devices-autopilot-all` | 60 | Dynamic, every device with a `ZTDId` |
| `zt-<env>-devices-autopilot-{corp-win,preprov,kiosk}` | 60 | Dynamic, by Autopilot group tag (`[OrderID]:<TAG>`) |
| `zt-<env>-devices-autopilot-device-preparation` | 60 | Added during OOBE by the Intune Provisioning Client |

## References

* [Secure endpoints with Zero Trust](https://learn.microsoft.com/en-us/security/zero-trust/deploy/endpoints)
* [Intune planning guide](https://learn.microsoft.com/en-us/intune/fundamentals/planning-guide)
* [Intune deployment guide](https://learn.microsoft.com/en-us/intune/fundamentals/setup-migration)
* [Security baselines in Intune](https://learn.microsoft.com/en-us/intune/device-security/security-baselines/overview)
* [Endpoint security policies](https://learn.microsoft.com/en-us/intune/device-security/endpoint-security-policies)
* [App protection data protection framework](https://learn.microsoft.com/en-us/intune/app-management/protection/data-protection-framework)
* [Windows Autopilot overview](https://learn.microsoft.com/en-us/autopilot/overview)
