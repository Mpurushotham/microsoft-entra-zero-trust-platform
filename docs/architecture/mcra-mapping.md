# MCRA mapping

The Microsoft Cybersecurity Reference Architectures describe how Microsoft security capabilities fit together across identity, devices, applications, data, infrastructure and security operations. This page shows which parts of the MCRA the platform implements, which it integrates with, and which are out of scope.

## MCRA-aligned architecture

```mermaid
flowchart TB
    subgraph IDN["Identity and access"]
        E1["Entra ID<br/>authentication methods"]
        E2["Conditional Access<br/>Zero Trust policy engine"]
        E3["ID Protection"]
        E4["ID Governance<br/>PIM, entitlement, reviews, LCW"]
        E5["Cloud Sync<br/>hybrid identity"]
    end
    subgraph EPT["Endpoints and devices"]
        D1["Intune MDM and MAM"]
        D2["Windows Autopilot"]
        D3["Defender for Endpoint"]
    end
    subgraph APPS["Applications"]
        A1["Microsoft 365"]
        A2["Enterprise apps<br/>migrated from AD FS"]
        A3["Defender for Cloud Apps"]
    end
    subgraph DATA["Data"]
        P1["App protection policies"]
        P2["Purview - integrates"]
    end
    subgraph INFRA["Infrastructure"]
        I1["Azure subscription<br/>state and workspace"]
        I2["Defender for Cloud - integrates"]
    end
    subgraph SOC["Security operations"]
        S1["Log Analytics"]
        S2["Microsoft Sentinel"]
        S3["Defender XDR"]
        S4["Defender for Identity"]
    end
    D1 -- "compliance" --> E2
    D3 -- "device risk" --> D1
    E3 -- "user and sign-in risk" --> E2
    E2 --> A1
    E2 --> A2
    A3 -- "session control" --> E2
    P1 --> A1
    IDN -- "logs" --> S1
    EPT -- "alerts" --> S3
    S4 -- "AD DS signals" --> S3
    S1 --> S2
    S3 <--> S2
```

## Coverage

| MCRA area | Capability | Status | Where |
|---|---|---|---|
| Identity and access | Microsoft Entra ID, passwordless authentication | Implemented | `10-entra-foundation` |
| Identity and access | Conditional Access | Implemented | `20-entra-conditional-access` |
| Identity and access | Privileged Identity Management, entitlement management, access reviews | Implemented | `30-entra-governance` |
| Identity and access | Hybrid identity, cloud authentication | Implemented | `40-hybrid-migration` |
| Identity and access | Microsoft Entra ID Protection | Consumed through risk-based policies | `20-entra-conditional-access` |
| Endpoints | Intune, security baselines, endpoint security | Implemented | `50-intune-foundation` |
| Endpoints | Windows Autopilot | Implemented | `60-intune-autopilot-zero-touch` |
| Endpoints | Defender for Endpoint onboarding | Implemented through EDR policy | `50-intune-foundation` |
| Applications | Enterprise application SSO | Implemented for migrated AD FS apps | `40-hybrid-migration` |
| Applications | Defender for Cloud Apps | Integration notes | [Security operations](../security-operations/README.md) |
| Data | App protection (MAM) | Implemented | `50-intune-foundation` |
| Data | Microsoft Purview | Out of scope | Not deployed |
| Infrastructure | Defender for Cloud | Out of scope | Not deployed |
| Security operations | Microsoft Sentinel, Defender XDR connector | Implemented | `70-security-operations` |
| Security operations | Defender for Identity | Integration notes | [Security operations](../security-operations/README.md) |

{% hint style="info" %}
"Integration notes" means the platform configures the Entra or Sentinel side and documents the product-side steps, because the product exposes no stable Terraform or Graph surface for the remainder.
{% endhint %}

## References

* [Microsoft Cybersecurity Reference Architectures (MCRA)](https://learn.microsoft.com/en-us/security/adoption/mcra)
* [Zero Trust adoption framework](https://learn.microsoft.com/en-us/security/zero-trust/adopt/zero-trust-adoption-overview)
* [Microsoft Defender XDR](https://learn.microsoft.com/en-us/defender-xdr/microsoft-365-defender)
* [Microsoft Defender for Identity](https://learn.microsoft.com/en-us/defender-for-identity/what-is)
* [Microsoft Defender for Cloud Apps](https://learn.microsoft.com/en-us/defender-cloud-apps/what-is-defender-for-cloud-apps)
