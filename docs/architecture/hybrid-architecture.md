# Hybrid identity architecture

Most organisations start with an Active Directory Domain Services forest, AD FS for federation and hybrid-joined devices. The target state removes AD FS, moves authentication to Microsoft Entra ID, and makes new devices Entra joined. AD DS remains the source of authority for users during the transition.

## Current state to target state

```mermaid
flowchart LR
    subgraph Current["Current state"]
        direction TB
        C_AD["AD DS forest"]
        C_SYNC["Entra Connect Sync"]
        C_ADFS["AD FS farm + WAP<br/>federated domain"]
        C_DEV["Hybrid-joined devices<br/>GPO + SCCM"]
        C_APPS["Apps as AD FS<br/>relying parties"]
        C_AD --> C_SYNC
        C_AD --> C_ADFS
        C_ADFS --> C_APPS
        C_AD --> C_DEV
    end
    subgraph Target["Target state"]
        direction TB
        T_AD["AD DS forest<br/>source of authority"]
        T_SYNC["Entra Cloud Sync<br/>PHS enabled"]
        T_ENTRA["Entra ID<br/>managed domain, cloud auth"]
        T_DEV["Entra-joined devices<br/>Intune + Autopilot"]
        T_APPS["Enterprise apps<br/>SAML / OIDC on Entra"]
        T_KERB["Cloud Kerberos trust<br/>WHfB SSO to on-prem"]
        T_AD --> T_SYNC --> T_ENTRA
        T_ENTRA --> T_APPS
        T_ENTRA --> T_DEV
        T_DEV --> T_KERB --> T_AD
    end
    Current ==>|"staged migration"| Target
```

## Component decisions

| Component | Current | Target | Decision record |
|---|---|---|---|
| Synchronisation | Entra Connect Sync | Entra Cloud Sync where supported; Connect Sync retained only for unsupported scenarios | [ADR-0002](adr/0002-cloud-sync-over-connect-sync.md) |
| Authentication | Federated through AD FS | Password hash sync with cloud authentication | Microsoft recommended method |
| Seamless SSO | Desktop SSO through AD FS | Primary Refresh Token on Entra-joined devices; Seamless SSO only for remaining domain-joined devices | Retire Seamless SSO when no hybrid devices remain |
| On-premises resource access | Kerberos from domain-joined devices | Windows Hello for Business cloud Kerberos trust | No PKI dependency |
| Applications | AD FS relying parties | Entra enterprise applications | Migrated per wave |
| Devices | Hybrid Entra join | Entra join through Autopilot at refresh | Device refresh cycle |
| Groups | AD DS groups | Cloud groups, written back to AD DS where on-premises apps need them | Cloud Sync group writeback |

## Why password hash sync

Microsoft recommends password hash synchronisation as the primary or backup authentication method because it removes the on-premises dependency during sign-in, enables leaked credential detection in ID Protection, and keeps users signing in if the on-premises environment is unavailable. Pass-through authentication is not used.

{% hint style="warning" %}
AD DS stays authoritative for user attributes until the organisation completes a separate source-of-authority switch. The platform migrates **authentication** and **applications**, not the HR-to-directory provisioning flow.
{% endhint %}

## References

* [What is hybrid identity](https://learn.microsoft.com/en-us/entra/identity/hybrid/whatis-hybrid-identity)
* [What is Microsoft Entra Cloud Sync](https://learn.microsoft.com/en-us/entra/identity/hybrid/cloud-sync/what-is-cloud-sync)
* [Password hash synchronization](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/whatis-phs)
* [Migrate from federation to cloud authentication](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/migrate-from-federation-to-cloud-authentication)
* [Windows Hello for Business cloud Kerberos trust](https://learn.microsoft.com/en-us/windows/security/identity-protection/hello-for-business/deploy/hybrid-cloud-kerberos-trust)
* [Group writeback with Cloud Sync](https://learn.microsoft.com/en-us/entra/identity/hybrid/group-writeback-cloud-sync)
* [Plan your Microsoft Entra join deployment](https://learn.microsoft.com/en-us/entra/identity/devices/device-join-plan)
