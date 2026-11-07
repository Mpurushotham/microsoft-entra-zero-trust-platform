environment = "dev"
ca_state    = "enabledForReportingButNotEnforced"

# Promote policies one at a time after reviewing report-only results.
policy_state_overrides = {
  CA000 = "enabled"
}
