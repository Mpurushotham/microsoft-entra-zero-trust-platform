# ADR-0006 Decompose the platform into eight independently deployable stacks

* Status: Accepted
* Date: 2026-11-01
* Deciders: Platform architecture

## Context

A single Terraform root for an entire tenant produces slow plans, a large blast radius and a single lock that serialises every change. Different teams own identity, endpoint and security operations.

## Decision

Split the platform into numbered stacks under `terraform/stacks/`, each with its own state key `<NN-topic>/<env>.tfstate`, its own workflow, and its own README:

`00-bootstrap`, `10-entra-foundation`, `20-entra-conditional-access`, `30-entra-governance`, `40-hybrid-migration`, `50-intune-foundation`, `60-intune-autopilot-zero-touch`, `70-security-operations`.

Cross-stack references use data sources looked up by display name in preference to `terraform_remote_state`, to keep stacks loosely coupled.

## Consequences

* A Conditional Access change never plans Intune resources.
* `CODEOWNERS` can assign stacks to the owning team.
* The deployment order matters for first deployment and is encoded in `end-to-end-deploy.yml`.
* Naming conventions become a contract between stacks.

## References

* [Microsoft Entra deployment plans](https://learn.microsoft.com/en-us/entra/architecture/deployment-plans)
* [Store Terraform state in Azure Storage](https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage)
