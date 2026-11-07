name_prefix = "zt"
environment = "prod"

migration_waves = ["pilot", "wave1", "wave2", "all"]
# Advance one wave per reviewed change: ["pilot"] -> ["pilot", "wave1"] -> ...
enabled_waves          = []
staged_features        = ["passwordHashSync", "seamlessSso"]
staged_rollout_enabled = true

migrated_applications   = {}
cloud_managed_group_ids = []
