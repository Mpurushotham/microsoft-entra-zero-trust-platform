# Rollback per stack

The default rollback for any stack is **revert the pull request and let the workflow apply the previous state**. Some resources cannot be restored that way because deleting them destroys data or identity. This page lists, per stack, what rollback means and what to watch out for.

## General procedure

{% stepper %}
{% step %}
### Stop the bleeding

If the change is actively harming sign-ins, act first: for Conditional Access, set the policy to report-only (through a revert or, if locked out, with a break-glass account).
{% endstep %}

{% step %}
### Revert

Open a revert pull request for the offending merge. The stack workflow plans it; review the plan for any **destroy** or **replace** actions before approving.
{% endstep %}

{% step %}
### Apply

Merge and approve the `prod` apply.
{% endstep %}

{% step %}
### Restore state if corrupted

If the state file itself is damaged, restore the previous blob version of `<NN-topic>/<env>.tfstate` in the state storage account from blob versioning, then rerun plan.
{% endstep %}
{% endstepper %}

## Stack notes

| Stack | Rollback method | Irreversible or risky items | Notes |
|---|---|---|---|
| `00-bootstrap` | Revert PR, apply locally with an elevated operator if the OIDC app itself is broken | Deleting the state storage account loses all state; deleting the OIDC app breaks every workflow | The state storage account has `prevent_destroy`; rollback is manual and rare |
| `10-entra-foundation` | Revert PR | Deleting groups removes memberships and breaks references in CA and Intune; deleted groups are soft-deleted for 30 days and can be restored | Never let a rollback delete the break-glass accounts or exclusion group |
| `20-entra-conditional-access` | Revert PR, or remove the policy from `policy_state_overrides` so it returns to report-only | None; policies are configuration only | Fastest and safest rollback is to report-only, not delete |
| `30-entra-governance` | Revert PR | Deleting an access package removes all its assignments and users lose access; deleting PIM eligibility removes admin access | Prefer disabling policies over deleting packages |
| `40-hybrid-migration` | Revert PR, plus `Invoke-MigrationRollback.ps1` | Domain conversion is not in Terraform; see [Migration rollback](../migration/rollback.md) | Mirror any script rollback in tfvars |
| `50-intune-foundation` | Revert PR | Removing a compliance policy can flip devices to not compliant if the tenant default marks devices without policy as not compliant | Check the assignment impact before applying |
| `60-intune-autopilot-zero-touch` | Revert PR | Deleting a deployment profile unassigns it from registered devices; devices already provisioned are unaffected | Device hashes registered by scripts are not in Terraform |
| `70-security-operations` | Revert PR | Deleting the Log Analytics workspace loses retained logs; disabling Sentinel deletes its content | Never destroy the workspace in `prod` as a rollback |

{% hint style="danger" %}
If a revert plan shows destroy or replace on break-glass accounts, the exclusion group, the state storage account, the OIDC application or the Log Analytics workspace, stop and escalate. These are never rolled back by deletion.
{% endhint %}

## References

* [Blob versioning](https://learn.microsoft.com/en-us/azure/storage/blobs/versioning-overview)
* [Conditional Access report-only mode](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-report-only)
* [Manage emergency access accounts](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-emergency-access)
* [Migrate from federation to cloud authentication](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/migrate-from-federation-to-cloud-authentication)
