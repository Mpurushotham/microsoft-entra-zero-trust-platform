environment                     = "prod"
compliance_grace_period_hours   = 24
defender_for_endpoint_connected = true
app_protection_level            = 2

asr_rule_overrides = {
  blockexecutablecontentfromemailclientandwebmail                   = "block"
  blockjavascriptorvbscriptfromlaunchingdownloadedexecutablecontent = "block"
  blockexecutionofpotentiallyobfuscatedscripts                      = "block"
  blockofficeapplicationsfromcreatingexecutablecontent              = "block"
}
