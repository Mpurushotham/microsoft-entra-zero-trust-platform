---
name: Configuration drift
about: The nightly plan found differences between Terraform and the tenant
title: "Drift detected: <stack> (<environment>)"
labels: drift
---

## Where

- Stack:
- Environment:
- Drift detection run:

## Triage

- [ ] Identify who made the change: Entra audit logs or the Sentinel `AuditLogs` table, filtered by the resource in the plan
- [ ] Out-of-band change by an administrator: confirm it was approved
- [ ] Unexpected actor or no change record: treat as a security incident and follow `docs/operations/` runbooks
- [ ] Decide: codify the change in Terraform (PR) or revert it by re-running the stack workflow with `apply`

## Resolution

<!-- PR link or re-apply run link. The issue closes automatically when the next nightly plan is clean. -->
