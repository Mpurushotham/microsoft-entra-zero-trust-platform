# Architecture decision records

Architecture decision records (ADRs) capture significant design choices, the context that drove them and their consequences. Each record is immutable once accepted; a later decision supersedes it with a new record rather than editing the old one.

| ADR | Title | Status |
|---|---|---|
| [0001](0001-terraform-azuread-msgraph.md) | Terraform with the azuread and msgraph providers | Accepted |
| [0002](0002-cloud-sync-over-connect-sync.md) | Entra Cloud Sync over Entra Connect Sync | Accepted |
| [0003](0003-conditional-access-report-only-first.md) | Conditional Access ships in report-only first | Accepted |
| [0004](0004-oidc-workload-identity-federation.md) | OIDC workload identity federation, no client secrets | Accepted |
| [0005](0005-autopilot-device-preparation.md) | Autopilot device preparation as the default Windows provisioning path | Accepted |
| [0006](0006-stack-decomposition.md) | Decompose the platform into eight independently deployable stacks | Accepted |

## Template

```markdown
# ADR-NNNN Title

* Status: Proposed | Accepted | Superseded by ADR-NNNN
* Date: YYYY-MM-DD
* Deciders: names or roles

## Context
## Decision
## Consequences
## Alternatives considered
## References
```

## References

* [Microsoft Entra deployment plans](https://learn.microsoft.com/en-us/entra/architecture/deployment-plans)
