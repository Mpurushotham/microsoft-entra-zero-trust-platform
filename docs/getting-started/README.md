# Overview

Getting the platform running is a three-stage journey. The first stage happens once, by a human, with elevated rights. Everything after it runs through GitHub Actions with no stored secrets.

```mermaid
flowchart LR
    P["1. Prerequisites<br/>licences, roles, tooling"] --> B["2. Bootstrap<br/>state storage + OIDC app"]
    B --> S["3. GitHub configuration<br/>secrets, variables, environments"]
    S --> D["4. end-to-end-deploy.yml<br/>dev"]
    D --> R["5. Review report-only<br/>CA insights"]
    R --> PR["6. Promote to prod"]
```

| Stage | Who | Duration | Output |
|---|---|---|---|
| [Prerequisites](prerequisites.md) | Identity lead, licensing owner | 1 to 5 days | Licences assigned, roles approved, tooling installed |
| [Bootstrap](bootstrap.md) | Privileged identity and subscription owner, once | 1 hour | State storage account, OIDC app registration, federated credentials |
| [First deployment](first-deployment.md) | Platform engineer through GitHub | 1 to 2 hours | All stacks deployed to `dev`, Conditional Access in report-only |

{% hint style="warning" %}
Never run the bootstrap against a production tenant before you have exercised it end to end in a non-production tenant. The Microsoft 365 developer programme or a dedicated test tenant is suitable.
{% endhint %}

## References

* [Microsoft Entra deployment plans](https://learn.microsoft.com/en-us/entra/architecture/deployment-plans)
* [Zero Trust deployment plan overview](https://learn.microsoft.com/en-us/security/zero-trust/deploy/overview)
* [Use GitHub Actions to connect to Azure with OpenID Connect](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect)
