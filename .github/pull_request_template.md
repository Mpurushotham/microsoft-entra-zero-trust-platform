## Summary

<!-- What changes and why. Link the issue or change request. -->

## Stacks affected

- [ ] 00-bootstrap (applied locally by an operator, CI plans only)
- [ ] 10-entra-foundation
- [ ] 20-entra-conditional-access
- [ ] 30-entra-governance
- [ ] 40-hybrid-migration
- [ ] 50-intune-foundation
- [ ] 60-intune-autopilot-zero-touch
- [ ] 70-security-operations
- [ ] Docs or workflows only

## Checklist

- [ ] Plan output in the PR comments reviewed for every affected stack and environment
- [ ] New Conditional Access policies ship in report-only (`enabledForReportingButNotEnforced`)
- [ ] Break-glass accounts remain excluded from every Conditional Access policy
- [ ] No tenant IDs, domains, secrets or personal data committed
- [ ] New Microsoft Graph permissions added to `terraform/stacks/00-bootstrap/locals.tf` and the docs
- [ ] Docs updated (`docs/`) where behaviour or operations change
- [ ] Rollback path written below

## Rollback

<!-- Revert commit and re-run the stack workflow, or the specific manual step. -->
