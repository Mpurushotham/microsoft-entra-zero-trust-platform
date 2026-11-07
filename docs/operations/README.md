# Operations overview

Day-two operations keep the platform safe and in line with Git. Each runbook has a trigger, an owner, a procedure and evidence to retain.

| Runbook | Trigger | Owner | Frequency |
|---|---|---|---|
| [Break-glass accounts](break-glass.md) | Tenant lock-out, or scheduled test | Identity lead and custodians | Monthly test |
| [Conditional Access promotion](ca-promotion.md) | Policy ready to move from report-only to enforced | Identity engineer | Per policy |
| [Drift response](drift-response.md) | `drift-detection.yml` issue, or Sentinel out-of-pipeline change incident | Platform on-call | As raised |
| [Rollback per stack](rollback-per-stack.md) | A deployment caused an incident | Platform on-call | As needed |

## Operating calendar

| Cadence | Activity |
|---|---|
| Daily | Review `drift-detection.yml` results and open drift issues |
| Weekly | Review Conditional Access insights for report-only policies; review sign-in failures by policy |
| Monthly | Break-glass sign-in test; PIM privileged role access review |
| Quarterly | Guest access reviews; review of the CI service principal's Graph permissions and directory roles |
| Per provider release | Upgrade providers in a branch, run plan against `dev`, review any beta Graph endpoint changes |

## References

* [Microsoft Entra security operations guide](https://learn.microsoft.com/en-us/entra/architecture/security-operations-introduction)
* [Manage emergency access accounts](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/security-emergency-access)
