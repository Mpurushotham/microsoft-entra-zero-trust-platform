name_prefix       = "zt"
environment       = "prod"
retention_in_days = 180

data_connectors = {
  entra_id_protection = true
  defender_xdr        = true
  office_365          = true
  threat_intelligence = true
}

break_glass_upns = [
  "bg-admin-01@contoso.onmicrosoft.com",
  "bg-admin-02@contoso.onmicrosoft.com",
]

business_hours = {
  start_hour       = 7
  end_hour         = 19
  utc_offset_hours = 0
  workdays         = [1, 2, 3, 4, 5]
}

mfa_fatigue_threshold = 5
disabled_rules        = []

tags = {
  owner       = "secops"
  cost-center = "security"
}
