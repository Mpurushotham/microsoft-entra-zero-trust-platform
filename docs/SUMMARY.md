# Table of contents

* [Microsoft Entra Zero Trust Platform](README.md)

## Getting started

* [Overview](getting-started/README.md)
* [Prerequisites and licensing](getting-started/prerequisites.md)
* [Bootstrap the platform](getting-started/bootstrap.md)
* [First end-to-end deployment](getting-started/first-deployment.md)

## Architecture

* [Architecture overview](architecture/README.md)
* [MCRA mapping](architecture/mcra-mapping.md)
* [Zero Trust pillars](architecture/zero-trust-pillars.md)
* [Identity architecture](architecture/identity-architecture.md)
* [Endpoint architecture](architecture/endpoint-architecture.md)
* [Hybrid identity architecture](architecture/hybrid-architecture.md)
* [Security operations architecture](architecture/security-operations-architecture.md)
* [Network and data flows](architecture/network-and-data-flows.md)
* [Architecture decision records](architecture/adr/README.md)
  * [ADR-0001 Terraform with azuread and msgraph](architecture/adr/0001-terraform-azuread-msgraph.md)
  * [ADR-0002 Cloud Sync over Connect Sync](architecture/adr/0002-cloud-sync-over-connect-sync.md)
  * [ADR-0003 Conditional Access report-only first](architecture/adr/0003-conditional-access-report-only-first.md)
  * [ADR-0004 OIDC workload identity federation](architecture/adr/0004-oidc-workload-identity-federation.md)
  * [ADR-0005 Autopilot device preparation](architecture/adr/0005-autopilot-device-preparation.md)
  * [ADR-0006 Stack decomposition](architecture/adr/0006-stack-decomposition.md)

## Identity

* [Identity overview](identity/README.md)
* [Entra foundation](identity/entra-foundation.md)
* [Conditional Access](identity/conditional-access.md)
* [Identity governance](identity/governance.md)
* [Privileged Identity Management](identity/pim.md)

## Migration

* [AD DS to Entra migration](migration/README.md)
* [Assessment and readiness](migration/assessment.md)
* [Cutover runbooks](migration/cutover-runbooks.md)
* [Migration rollback](migration/rollback.md)

## Endpoint

* [Endpoint overview](endpoint/README.md)
* [Intune foundation](endpoint/intune.md)
* [Autopilot zero-touch provisioning](endpoint/autopilot-zero-touch.md)
* [Compliance and Conditional Access](endpoint/compliance.md)

## Security operations

* [Security operations](security-operations/README.md)

## Deployment

* [Deployment overview](deployment/README.md)
* [GitHub Actions workflows](deployment/workflows.md)
* [OIDC trust](deployment/oidc.md)
* [Environments](deployment/environments.md)
* [End-to-end deployment](deployment/end-to-end.md)

## Operations

* [Operations overview](operations/README.md)
* [Break-glass accounts](operations/break-glass.md)
* [Conditional Access promotion](operations/ca-promotion.md)
* [Drift response](operations/drift-response.md)
* [Rollback per stack](operations/rollback-per-stack.md)

## Reference

* [Reference overview](reference/README.md)
* [Microsoft Learn references](reference/microsoft-learn-links.md)
* [Licensing matrix](reference/licensing-matrix.md)
* [Graph permissions per stack](reference/graph-permissions.md)
* [Glossary](reference/glossary.md)
* [Contributing](contributing.md)
