# ADR-0004 OIDC workload identity federation, no client secrets

* Status: Accepted
* Date: 2026-11-01
* Deciders: Platform architecture, Security

## Context

The deployment identity holds powerful Microsoft Graph application permissions. A leaked client secret or certificate would let an attacker reconfigure Conditional Access for the whole tenant.

## Decision

* Deployment applications have **no** client secret and **no** certificate.
* Each environment has a read-only plan application trusting `repo:<owner>/<repo>:pull_request` and `repo:<owner>/<repo>:ref:refs/heads/main`, and an apply application trusting only `repo:<owner>/<repo>:environment:<env>`.
* GitHub Actions obtains tokens through workload identity federation.
* Apply jobs always run inside a GitHub environment, so only an approved `prod` job can obtain a `prod` token.
* Terraform providers and the azurerm backend use `use_oidc = true` and read `ARM_CLIENT_ID`, `ARM_TENANT_ID` and `ARM_SUBSCRIPTION_ID` from the environment.

## Consequences

* Nothing to rotate, nothing to leak.
* Tokens are short-lived and bound to the job.
* Federated credential subjects must match exactly; renaming the repository or an environment breaks deployment until the credentials are updated through `00-bootstrap`.
* Separating plan and apply identities means pull requests can never write to the tenant.

See [OIDC trust](../../deployment/oidc.md) for the sequence.

## References

* [Workload identity federation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation)
* [Use GitHub Actions to connect to Azure with OpenID Connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect)
