# Glossary

| Term | Meaning |
|---|---|
| AD DS | Active Directory Domain Services, the on-premises directory |
| AD FS | Active Directory Federation Services, the on-premises federation server being retired |
| ADE | Apple Automated Device Enrollment through Apple Business Manager |
| ADR | Architecture decision record |
| APP | App protection policy, Intune mobile application management for iOS and Android |
| ASR | Attack surface reduction rules in Microsoft Defender for Endpoint |
| AU | Administrative unit, a container that scopes Entra role assignments |
| Authentication strength | A Conditional Access grant control requiring specific authentication method combinations |
| Autopilot device preparation | Second-generation Windows Autopilot that needs no hardware hash registration |
| Break-glass account | Emergency access account excluded from Conditional Access, used only when normal admin access fails |
| CA | Conditional Access, the Entra policy engine for access decisions |
| Cloud Kerberos trust | Windows Hello for Business deployment model where Entra ID issues partial Kerberos tickets for on-premises resources |
| Cloud Sync | Microsoft Entra Cloud Sync, agent-based synchronisation from AD DS configured in the cloud |
| Connect Sync | Microsoft Entra Connect Sync, server-based synchronisation engine |
| Drift | Difference between the configuration in Git and the live tenant |
| EDR | Endpoint detection and response |
| ESP | Enrollment Status Page, shown during Autopilot provisioning |
| Federated credential | Trust between an Entra application and an external OIDC issuer, used instead of a secret |
| JML | Joiner, mover, leaver lifecycle |
| LAPS | Windows Local Administrator Password Solution |
| LCW | Lifecycle workflows in Microsoft Entra ID Governance |
| MAM | Mobile application management |
| MCRA | Microsoft Cybersecurity Reference Architectures |
| MDM | Mobile device management |
| OIDC | OpenID Connect |
| PHS | Password hash synchronisation |
| PIM | Privileged Identity Management |
| PRT | Primary Refresh Token, the SSO artifact on Entra-joined and registered devices |
| Report-only | Conditional Access state `enabledForReportingButNotEnforced`; evaluated and logged but not enforced |
| Seamless SSO | Desktop single sign-on for domain-joined devices using a Kerberos computer account in AD DS |
| Staged rollout | Moving selected groups of users from federated to cloud authentication before converting the domain |
| TAP | Temporary Access Pass, a time-limited passcode for onboarding and recovery |
| WAP | Web Application Proxy, publishes AD FS to the internet |
| WHfB | Windows Hello for Business |
| ZTDId | Zero Touch Device ID, the attribute on Autopilot-registered device objects used in dynamic group rules |

## References

* [Zero Trust overview](https://learn.microsoft.com/en-us/security/zero-trust/zero-trust-overview)
* [Microsoft Cybersecurity Reference Architectures (MCRA)](https://learn.microsoft.com/en-us/security/adoption/mcra)
