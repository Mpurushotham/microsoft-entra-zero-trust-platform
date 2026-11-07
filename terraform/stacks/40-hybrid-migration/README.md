# 40-hybrid-migration

Entra-side configuration for migrating from on-premises Active Directory Domain Services and
AD FS to Microsoft Entra ID as the identity provider. The on-premises steps (assessment, sync
agent install, domain conversion, rollback) are in [`scripts/hybrid-migration`](../../../scripts/hybrid-migration/README.md).

## What this stack manages

| File | Resources |
|---|---|
| `main.tf` → `hybrid-staged-rollout` | Wave groups `<prefix>-<env>-hybrid-wave-{pilot,wave1,wave2,all}`, feature rollout policies for `passwordHashSync` and `seamlessSso` (optionally `certificateBasedAuthentication`), wave attachment |
| `main.tf` → `hybrid-app-migration` | Enterprise applications that replace AD FS relying party trusts (SAML and OIDC), signing certificates, claims mapping, group assignments |
| `group_soa.tf` | Source-of-authority conversion of synced groups to cloud-managed (Graph beta `onPremisesSyncBehavior`) |

## What it deliberately does not manage

| Item | Why | Where |
|---|---|---|
| Entra Cloud Sync / Connect Sync configuration | Configured by the provisioning agent and the Entra admin center or Graph synchronization API against an agent registration; not a declarative tenant object | Runbook phase 2 |
| Password hash sync enablement | A property of the sync engine, set in the Connect wizard or the Cloud Sync configuration | Runbook phase 2 |
| Seamless SSO computer account (`AZUREADSSOACC`) | Created on-premises by the `AzureADSSO` PowerShell module | Runbook phase 2 |
| Domain federation → managed | One-way, tenant-wide cutover with an outage window; must run interactively with prechecks and rollback | `Convert-DomainToManaged.ps1` |
| Wave membership | Batched (200-user first-population limit) and validated per wave | `Start-StagedRolloutWave.ps1` |
| Device migration | Devices move by Autopilot reset/re-provision, not configuration | Stack `60-intune-autopilot-zero-touch` |

## Sync engine decision

Microsoft recommends **Entra Cloud Sync** for new deployments and Connect Sync only where a
Cloud Sync gap applies. Check the current
[comparison](https://learn.microsoft.com/entra/identity/hybrid/cloud-sync/what-is-cloud-sync#comparison-between-microsoft-entra-connect-and-cloud-sync)
before choosing.

| Requirement | Cloud Sync | Connect Sync |
|---|---|---|
| Multiple disconnected forests, lightweight agents, HA by adding agents | Yes | Single server + staging server |
| Password hash sync | Yes | Yes |
| Pass-through authentication | No | Yes |
| Device objects (hybrid Entra join) | No | Yes |
| Group provisioning to AD (cloud groups → AD) | Yes | Group writeback v2 retired |
| Custom sync rules and complex attribute flows | Attribute mapping expressions only | Yes |

Default for this platform: Cloud Sync with PHS. Keep Connect Sync only while hybrid-joined
devices still need device sync; retire it once every device is Entra joined.

## Migration phases

| Phase | Outcome | Terraform change |
|---|---|---|
| 0 Assess | AD hygiene report, AD FS RP inventory | none |
| 1 Prepare | UPN suffixes routable, PHS running, Seamless SSO/cloud Kerberos trust ready | apply with `enabled_waves = []` (groups + policies) |
| 2 Pilot | Pilot users authenticate in the cloud | `enabled_waves = ["pilot"]` |
| 3 Waves | wave1, wave2, all migrated | append one wave per PR |
| 4 Apps | AD FS RPs repointed to Entra | populate `migrated_applications` |
| 5 Cutover | Domain converted to managed | none (script), then `staged_rollout_enabled = false` |
| 6 Decommission | AD FS farm and WAP removed, groups cloud-managed | `cloud_managed_group_ids`, then remove waves |

Once the domain is managed, staged rollout no longer has an effect. Remove the policies after
the rollback window closes by setting `enabled_waves = []` and `staged_features = []`.

## Deploy

```bash
terraform init \
  -backend-config="resource_group_name=$TFSTATE_RG" \
  -backend-config="storage_account_name=$TFSTATE_SA" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=40-hybrid-migration/dev.tfstate" \
  -backend-config="use_oidc=true" \
  -backend-config="use_azuread_auth=true"
terraform plan -var-file=env/dev.tfvars
```

Offline checks: `terraform init -backend=false && terraform validate && terraform test`
(the test uses mocked providers).

Graph application permissions for the CI identity: `Directory.ReadWrite.All`,
`Group.ReadWrite.All`, `Application.ReadWrite.All`, `AppRoleAssignment.ReadWrite.All`,
`Policy.ReadWrite.ApplicationConfiguration`, and `Group-OnPremisesSyncBehavior.ReadWrite.All`
for group source-of-authority conversion.

## Outputs

| Name | Consumer |
|---|---|
| `wave_groups` | `Start-StagedRolloutWave.ps1`, Conditional Access/Intune targeting by display name |
| `feature_rollout_policy_ids` | `Invoke-MigrationRollback.ps1` |
| `migrated_applications` | App owners, cutover checklist |
| `saml_signing_certificate_thumbprints` | SAML service provider reconfiguration |
