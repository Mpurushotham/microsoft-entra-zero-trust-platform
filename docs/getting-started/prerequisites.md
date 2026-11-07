# Prerequisites and licensing

## Licensing

Features are gated by licence. The platform detects nothing automatically: if a licence is missing, the related resources either fail to apply or silently do nothing. Confirm licensing before the first deployment. The full feature-by-feature table is in the [licensing matrix](../reference/licensing-matrix.md).

| Licence | Minimum for | Included in |
|---|---|---|
| Microsoft Entra ID P1 | Conditional Access, dynamic groups, Cloud Sync group writeback, administrative units with dynamic membership | Microsoft 365 E3, EMS E3 |
| Microsoft Entra ID P2 | Risk-based Conditional Access, PIM, access reviews, ID Protection | Microsoft 365 E5, EMS E5 |
| Microsoft Entra ID Governance | Lifecycle workflows, advanced entitlement management | Add-on to P1 or P2 |
| Microsoft Intune Plan 1 | MDM, compliance, Autopilot, app protection | Microsoft 365 E3 and E5, EMS E3 and E5 |
| Microsoft Defender XDR workloads | Defender for Endpoint P2, Identity, Office 365 P2, Cloud Apps | Microsoft 365 E5 |
| Azure subscription | Terraform state, Log Analytics, Microsoft Sentinel | Pay as you go |

{% hint style="info" %}
A Microsoft 365 E5 tenant covers every stack except lifecycle workflows, which need Microsoft Entra ID Governance. With E3 only, set the risk-based policies and PIM-related inputs off and keep `30-entra-governance` limited to entitlement management features available under P1.
{% endhint %}

## Roles

| Activity | Role required | Notes |
|---|---|---|
| Bootstrap (once) | Owner on the target subscription **and** Privileged Role Administrator plus Cloud Application Administrator in Entra ID (or Global Administrator) | Needed to create the app registration, grant admin consent for Microsoft Graph application permissions and create role assignments |
| Day-to-day deployment | None for humans; the CI service principal holds the permissions | Humans approve `prod` deployments in GitHub |
| Break-glass test | Holder of the emergency access credentials | Two named custodians, see [Break-glass accounts](../operations/break-glass.md) |
| Conditional Access promotion | Conditional Access Administrator to review insights, repository maintainer to merge | Promotion is a pull request, not a portal change |

## Tooling on the bootstrap workstation

| Tool | Version | Purpose |
|---|---|---|
| Terraform | 1.9 or later | Applies `00-bootstrap` locally the first time |
| Azure CLI | Current | Interactive sign-in for the bootstrap only |
| PowerShell | 7.4 or later | Bootstrap, migration and Autopilot scripts |
| Microsoft Graph PowerShell SDK | Current | `Microsoft.Graph.Authentication` and related modules used by scripts |
| GitHub CLI | Current | Optional, sets repository secrets and variables |
| pre-commit, tflint, checkov | Current | Local quality gates, see [Contributing](../contributing.md) |

## Tenant readiness checklist

{% stepper %}
{% step %}
### Confirm the custom domain

Verify the organisation's custom domain, for example `contoso.com`, in Microsoft Entra ID. Federated domains stay federated until the [cutover runbook](../migration/cutover-runbooks.md) converts them.
{% endstep %}

{% step %}
### Disable security defaults

Conditional Access and security defaults are mutually exclusive. Disable security defaults only at the moment `20-entra-conditional-access` is first applied, so the tenant is never left unprotected.
{% endstep %}

{% step %}
### Choose two break-glass custodians

Name two people who will hold the FIDO2 security keys for the emergency access accounts created by `10-entra-foundation`.
{% endstep %}

{% step %}
### Create the GitHub environments

Create `dev` and `prod` environments in the repository. Add required reviewers to `prod`. See [Environments](../deployment/environments.md).
{% endstep %}
{% endstepper %}

## References

* [Microsoft Entra licensing](https://learn.microsoft.com/en-us/entra/fundamentals/licensing)
* [Microsoft Entra ID Governance licensing fundamentals](https://learn.microsoft.com/en-us/entra/id-governance/licensing-fundamentals)
* [Microsoft Intune licensing](https://learn.microsoft.com/en-us/intune/fundamentals/licensing)
* [Microsoft Entra built-in roles](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference)
* [Best practices for Microsoft Entra roles](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/best-practices)
