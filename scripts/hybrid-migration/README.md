# Hybrid migration scripts

Runbook for moving from on-premises Active Directory Domain Services and AD FS to Microsoft
Entra ID authentication, following the Microsoft Learn method: sync with Entra Cloud Sync (or
Connect Sync), enable password hash sync, move users in waves with **staged rollout**, migrate
AD FS relying parties to enterprise applications, convert the domain to managed, then
decommission AD FS. Entra-side objects come from
[`terraform/stacks/40-hybrid-migration`](../../terraform/stacks/40-hybrid-migration/README.md).

## Scripts

| Script | Runs on | Purpose | Changes anything |
|---|---|---|---|
| `Invoke-ADReadinessAssessment.ps1` | Domain-joined admin host (RSAT AD) | IdFix-style checks: UPN suffix, invalid characters, duplicates, stale and privileged accounts | No (writes report) |
| `Get-ADFSRelyingPartyInventory.ps1` | Primary AD FS server | Exports RP trusts, application groups and claim rules; rates each Ready / NeedsReview / Blocked; emits a tfvars starting point | No (writes report) |
| `Test-HybridSyncHealth.ps1` | Any host with Microsoft Graph PowerShell | Sync enabled, last sync, PHS heartbeat, domain auth types, provisioning errors; non-zero exit on failure | No |
| `Start-StagedRolloutWave.ps1` | Graph host | Validates and adds a wave of users to its staged rollout group | Group membership |
| `Convert-DomainToManaged.ps1` | Graph host, cloud-only admin | Prechecks, federation backup, `Update-MgDomain` to Managed; preview unless `-Execute` | Domain authentication |
| `Invoke-MigrationRollback.ps1` | Graph host | Remove wave users, disable staged rollout, or restore federation from backup; preview unless `-Execute` | Depends on action |
| `Get-DeviceJoinStateReport.ps1` | Graph host | Hybrid joined vs Entra joined vs registered devices, Autopilot readiness | No |

Each script is self-contained so it can be copied to the host it runs on (AD FS servers rarely
have Graph modules, and Graph hosts rarely have RSAT). All support `-WhatIf` and comment-based
help (`Get-Help ./<script>.ps1 -Full`). No script stores or accepts secrets: Graph sign-in is
interactive (`Connect-MgGraph`) or an existing context from workload identity federation.

Prerequisites: PowerShell 7.2+, `Microsoft.Graph.Authentication` and
`Microsoft.Graph.Identity.DirectoryManagement`; RSAT `ActiveDirectory` for the assessment; the
`ADFS` module (on the AD FS server) for the inventory.

## Ordered runbook

### Phase 0 — Assess (weeks 1–2)

1. `./Invoke-ADReadinessAssessment.ps1 -SearchBase '<OU DN>' -VerifiedDomain contoso.com -OutputPath ./out/assessment`
   Fix every `Error` row. Exclude `PrivilegedAccount` objects from the sync scope; administrators use
   cloud-only accounts.
2. On the AD FS server: `./Get-ADFSRelyingPartyInventory.ps1 -OutputPath C:\Migration\adfs`
   Cross-check with the Entra admin center **AD FS application activity** report (needs Connect
   Health for AD FS). Add a `MigrationStatus` column (`NotMigrated` / `Migrated`) to `inventory.csv`;
   it is read later by the cutover prechecks.
3. `./Get-DeviceJoinStateReport.ps1 -IncludeIntune` to size the device track.

Exit: zero assessment errors in scope, every RP has an owner and verdict.

### Phase 1 — Prepare sync and authentication (weeks 2–4)

1. Choose the sync engine (decision table in the stack README). Default: **Entra Cloud Sync**,
   installed as two or more provisioning agents; keep Connect Sync only while hybrid-joined
   devices must sync.
2. Add routable UPN suffixes, verify them in Entra, update user UPNs.
3. Enable **password hash sync** (Cloud Sync configuration or Connect wizard) while the domain stays
   federated. PHS also provides leaked-credential detection.
4. Enable **Seamless SSO** for down-level devices (`AzureADSSO` module creates `AZUREADSSOACC`),
   and deploy **Windows Hello for Business cloud Kerberos trust** (`New-AzureADKerberosServer` from the
   `AzureADHybridAuthenticationManagement` module) so Entra-joined devices get on-prem Kerberos tickets
   for file shares and legacy apps.
5. `terraform apply` 40-hybrid-migration with `enabled_waves = []`: creates wave groups and rollout policies.
6. `./Test-HybridSyncHealth.ps1` must return `Healthy = True`.

Exit: PHS heartbeat under 2 hours, sync errors triaged.

### Phase 2 — Pilot (weeks 4–6)

1. `./Start-StagedRolloutWave.ps1 -Wave pilot -Environment prod -UserListPath ./waves/pilot.csv -WhatIf`, then without `-WhatIf`.
   Pilot: IT staff plus one champion per business unit, under 200 users.
2. Set `enabled_waves = ["pilot"]` and apply (PR review).
3. Validate: sign-in logs show the pilot users authenticating at Entra (no redirect to AD FS),
   MFA and Conditional Access behave, Seamless SSO / WHfB cloud Kerberos trust works on-prem.

Rollback: `./Invoke-MigrationRollback.ps1 -Action RemoveWaveUsers -Wave pilot -Environment prod -Execute`.

### Phase 3 — Waves (weeks 6–12)

Repeat phase 2 for `wave1`, `wave2` and `all`, two weeks per wave. For groups above 200 users:
add the first 200, attach the wave in Terraform, then rerun the script to add the rest.
Run `Test-HybridSyncHealth.ps1` before each wave.

### Phase 4 — Application migration (weeks 6–14, parallel)

1. Copy `migrated_applications.auto.tfvars.json` entries rated Ready into the stack tfvars; recreate
   NeedsReview apps by hand-tuning `claims_schema` and Conditional Access.
2. Apply, hand the SAML signing certificate (`saml_signing_certificate_thumbprints` output, metadata
   from the enterprise app) to each service provider, switch the SP to Entra, test, then disable the
   RP trust in AD FS. Mark the row `Migrated`.
3. Blocked apps (custom attribute stores, SQL/LDAP claim queries) need app changes or Entra
   application proxy / a partner IdP integration before AD FS can go.

### Phase 5 — Domain cutover (week 14, change window)

1. `./Test-HybridSyncHealth.ps1` healthy.
2. `./Convert-DomainToManaged.ps1 -DomainName contoso.com -RelyingPartyInventoryPath ./inventory.csv` (preview).
3. `./Convert-DomainToManaged.ps1 -DomainName contoso.com -Execute -BackupPath ./federation-backup`
   with a cloud-only Global Administrator. If Connect Sync manages AD FS, use **Change user sign-in**
   in the Connect wizard instead.
4. Set `staged_rollout_enabled = false` and apply.

Rollback: `./Invoke-MigrationRollback.ps1 -Action RestoreFederation -DomainName contoso.com -FederationBackupPath <backup> -Execute`
(AD FS must still be running with the same token-signing certificate).

### Phase 6 — Devices and decommission (weeks 14–26)

1. Devices: `Get-DeviceJoinStateReport.ps1` lists hybrid joined Windows devices. `ReadyToReprovision`
   devices are wiped and re-enrolled through Autopilot user-driven Entra join (stack
   `60-intune-autopilot-zero-touch`); `ImportAutopilotHash` devices need hash import first
   (`scripts/intune`). Autopilot Reset keeps the current join type, so use it only for devices that
   are already Entra joined.
2. Groups: convert synced groups that no longer need AD authority with `cloud_managed_group_ids`
   (group source-of-authority conversion). Use Cloud Sync group provisioning to AD for groups that
   on-prem resources still read.
3. After a 30-day rollback window with no AD FS sign-ins: remove the AD FS relying party for
   Microsoft 365, shut down WAP and AD FS servers, revoke AD FS certificates, delete the AD FS
   DNS records, remove `enabled_waves`/`staged_features` and the wave groups.
4. Disable Seamless SSO once every device is Entra joined; retire Connect Sync once no device
   objects need sync.

## Timeline (for planning)

| Phase | Start week | Duration (weeks) | Depends on |
|---|---|---|---|
| 0 Assess | 1 | 2 | — |
| 1 Prepare | 2 | 3 | 0 |
| 2 Pilot | 4 | 2 | 1 |
| 3 Wave 1 | 6 | 2 | 2 |
| 3 Wave 2 | 8 | 2 | Wave 1 |
| 3 All | 10 | 2 | Wave 2 |
| 4 Apps | 6 | 8 | 2 |
| 5 Cutover | 14 | 1 | 3, 4 |
| 6 Devices | 14 | 12 | 5 |
| 6 Decommission AD FS | 18 | 2 | 5 + 30-day window |
