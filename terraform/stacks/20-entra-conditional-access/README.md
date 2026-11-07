# 20-entra-conditional-access

Conditional Access baseline modelled on Microsoft's
[Conditional Access templates](https://learn.microsoft.com/entra/identity/conditional-access/concept-conditional-access-policy-common)
and the [persona-based Zero Trust framework](https://learn.microsoft.com/azure/architecture/guide/security/conditional-access-framework).
Every policy ships **report-only** (`ca_state = "enabledForReportingButNotEnforced"`) and
excludes the emergency access group.

## Policy set

Display names: `<prefix>-<env>-CA<nnn>-<Persona>-<Purpose>-<Apps>-<Platform>-<Control>`.

| # | Persona | Policy | Licence |
|---|---|---|---|
| CA000 | Global | Block legacy authentication | P1 |
| CA001 | Global | Block device code flow and authentication transfer | P1 |
| CA002 | Global | Block unknown or unsupported device platforms | P1 |
| CA003 | Global | Block sign-in from blocked countries (`enable_country_block`) | P1 |
| CA004 | Global | Register security info from untrusted networks with TAP or a strong method | P1 |
| CA005 | Global | Require MFA to register or join devices | P1 |
| CA006 | Global | Require MFA for Azure management | P1 |
| CA100 | Admins | Require phishing-resistant MFA (custom authentication strength) | P1 |
| CA101 | Admins | Require compliant or Microsoft Entra hybrid joined device | P1 + Intune |
| CA102 | Admins | Sign-in frequency 4 h, no persistent browser | P1 |
| CA200 | Internals | Require MFA for all users (service accounts and sync role excluded) | P1 |
| CA201 | Internals | Office 365 on iOS/Android: app protection policy or compliant device | P1 + Intune |
| CA202 | Internals | Unmanaged devices: 1 h sign-in frequency, no persistent browser | P1 |
| CA203 | Internals | Office 365 in the browser on unmanaged devices: app enforced restrictions | P1 |
| CA300 | Internals | Medium/high sign-in risk: MFA every time (`enable_risk_policies`) | P2 |
| CA301 | Internals | High user risk: MFA and password change (`enable_risk_policies`) | P2 |
| CA400 | Guests | Require MFA for all guest and external user types | P1 |
| CA500 | Workload identities | Block service principals outside trusted locations (`enable_workload_identity_policy`) | Workload ID Premium |
| CA600 | Admins | Token protection for Exchange, SharePoint and Teams on Windows (`enable_token_protection`, Graph beta) | P1 |

Administrator policies target directory **role template IDs**, so new admins are covered
without group maintenance. Built-in strength "Multifactor authentication" is referenced by
its fixed ID; custom strengths and named locations come from `10-entra-foundation`.

## Rollout

1. Apply with every policy report-only.
2. Use the Conditional Access insights workbook and sign-in logs for 7 to 14 days.
3. Promote one policy at a time with `policy_state_overrides = { CA000 = "enabled" }`.
   Suggested order: CA000, CA001, CA004, CA005, CA100, CA200, CA400, CA002, then the rest.
4. Before enabling CA101/CA201, make sure Intune compliance and app protection policies
   (stack `50-intune-foundation`) are assigned and devices report compliant.

## Dependencies

Resolved by display name from `10-entra-foundation`:
`<prefix>-<env>-ca-exclude-emergency-access`, `<prefix>-<env>-persona-service-accounts`,
`<prefix>-<env>-nl-blocked-countries`, `<prefix>-<env>-as-phishing-resistant-admins`,
`<prefix>-<env>-as-security-info-registration`.

Graph permissions: `Policy.ReadWrite.ConditionalAccess`, `Policy.Read.All`,
`Application.Read.All`, `Group.Read.All`.

## Outputs

`policies`: object ID, display name and state per policy number.
