environment = "prod"

# Documentation ranges (RFC 5737); replace with the production egress IPs.
corporate_egress_ranges = ["198.51.100.0/24", "203.0.113.0/24"]

allowed_countries = ["US", "GB"]
blocked_countries = ["KP", "IR", "SY", "CU", "RU", "BY"]

disable_sms_and_voice             = true
fido2_attestation_enforced        = true
enable_custom_security_attributes = true
