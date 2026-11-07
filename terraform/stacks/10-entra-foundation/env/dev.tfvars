environment = "dev"

# Documentation ranges (RFC 5737); replace with the dev tenant's real egress IPs.
corporate_egress_ranges = ["203.0.113.0/24"]

allowed_countries = ["US", "GB"]

# Keep SMS/voice available in dev until the registration campaign has run.
disable_sms_and_voice = false
