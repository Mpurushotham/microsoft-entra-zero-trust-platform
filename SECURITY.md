# Security policy

## Reporting a vulnerability

Please do not open a public issue for security problems.

Report vulnerabilities privately through GitHub's **Report a vulnerability** button on the repository's **Security** tab (private vulnerability reporting). Include:

* the affected file, stack or workflow;
* the impact, for example a Conditional Access bypass, privilege escalation in a deployment identity, or secret exposure;
* steps to reproduce in a test tenant;
* any suggested fix.

You can expect an acknowledgement within 5 working days and a status update within 14 days. Fixes are released through a normal pull request once a patch is available, and reporters are credited unless they prefer otherwise.

## Scope

In scope:

* Terraform in `terraform/` that weakens the intended security posture, such as a policy that fails open or an exclusion broader than documented.
* GitHub Actions workflows in `.github/workflows/`, including OIDC trust and permissions.
* PowerShell in `scripts/`.
* Documentation that would lead an operator to an insecure configuration.

Out of scope: vulnerabilities in Microsoft services, Terraform providers or GitHub itself. Report those to the vendor.

## No-secrets policy

This repository must never contain:

* client secrets, certificates, private keys, passwords, access tokens or connection strings;
* real tenant IDs, subscription IDs, domain names, user principal names or object IDs (use `contoso.com` style placeholders and all-zero GUIDs);
* Terraform state files, plan files or plan output;
* Autopilot hardware hashes or device serial numbers;
* exported reports from the migration scripts.

Enforcement:

* Deployment identities authenticate with OIDC workload identity federation and have no secrets to leak.
* `gitleaks` runs in pre-commit and in `ci-quality.yml`; `detect-private-key` runs in pre-commit.
* `.gitignore` excludes state, plan and report files.

If a secret is committed by mistake, treat it as compromised: revoke or rotate it immediately, then remove it from history. Removing the commit alone is not enough.

## Supported versions

Only the `main` branch is supported.
