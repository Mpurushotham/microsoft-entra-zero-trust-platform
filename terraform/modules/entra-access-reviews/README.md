# entra-access-reviews

Recurring Microsoft Entra **access reviews** defined through Microsoft Graph v1.0
(`identityGovernance/accessReviews/definitions`), because `azuread` has no standalone
access review resource. Follows Microsoft's
[access reviews deployment plan](https://learn.microsoft.com/entra/id-governance/deploy-access-reviews).

## Review types

| Input | Scope | Reviewers |
|---|---|---|
| `group_membership_reviews` | Transitive members (or guests only) of one group | Members of reviewer groups and/or each user's manager; fallback groups when nobody answers |
| `inactive_guest_review` | Guests inactive for N days in every Microsoft 365 group | Group owners, then fallback groups |

Defaults follow the Zero Trust "assume breach / least privilege" posture: quarterly
recurrence, 14-day window, justification required, recommendations shown, **unreviewed
access is denied and auto-applied**.

## Notes

- Reviews of PIM-eligible role assignments are created in PIM. Reviewing the members of the
  role-assignable `pim-*` groups (this module) covers the PIM-for-Groups model.
- `start_date` is the first instance date. Changing it after creation updates the series.
- Requires Microsoft Entra ID P2 or ID Governance. The deployment identity needs
  `AccessReview.ReadWrite.All`.

## Inputs

| Name | Type | Default |
|---|---|---|
| `name_prefix`, `environment` | string | required |
| `start_date` | string `YYYY-MM-DD` | required |
| `group_membership_reviews` | map(object) | `{}` |
| `inactive_guest_review` | object | enabled, 90 days |

## Outputs

| Name | Description |
|---|---|
| `review_definition_ids` | `{ key => definition id }` |

## Example

```hcl
module "access_reviews" {
  source      = "../../modules/entra-access-reviews"
  name_prefix = "zt"
  environment = "prod"
  start_date  = "2027-01-04"
  group_membership_reviews = {
    "pim-global-administrators" = {
      group_object_id           = data.azuread_group.pim["pim-global-administrators"].object_id
      description               = "Quarterly attestation of Tier-0 administrators."
      reviewer_group_object_ids = [data.azuread_group.approvers.object_id]
    }
  }
}
```
