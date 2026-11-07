# ADR-0003 Conditional Access ships in report-only first

* Status: Accepted
* Date: 2026-11-01
* Deciders: Identity architecture, Security operations

## Context

A wrong Conditional Access policy can lock every user, including administrators, out of the tenant. Microsoft's Conditional Access deployment plan recommends evaluating impact with report-only mode and the insights and reporting workbook before enforcement.

## Decision

* Every policy in `20-entra-conditional-access` is created with state `enabledForReportingButNotEnforced`, controlled by the variable `ca_state`.
* Promotion to `enabled` is a pull request that adds named policies to `policy_state_overrides`, for example `{ CA000 = "enabled" }`, after the evidence in [Conditional Access promotion](../../operations/ca-promotion.md) has been gathered.
* The break-glass exclusion group is excluded from every policy, enforced by a variable validation in the stack.

## Consequences

* A first deployment cannot lock anyone out.
* There is a window in which the tenant is protected only by policies already enforced. Security defaults stay on until the MFA policies are promoted, or the MFA baseline is promoted first.
* Report-only policies that require compliant devices can prompt macOS, iOS and Android users for a device certificate during evaluation; this is a known Microsoft behaviour and is communicated to users.

## Alternatives considered

| Option | Why not chosen |
|---|---|
| Enforce immediately with pilot group scoping | Still risks lock-out of pilot admins; no tenant-wide impact data |
| Separate pilot and production policy copies | Doubles the policy count and the chance of divergence |

## References

* [Plan a Conditional Access deployment](https://learn.microsoft.com/en-us/entra/identity/conditional-access/plan-conditional-access)
* [Conditional Access report-only mode](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-report-only)
* [Conditional Access insights and reporting](https://learn.microsoft.com/en-us/entra/identity/conditional-access/howto-conditional-access-insights-reporting)
