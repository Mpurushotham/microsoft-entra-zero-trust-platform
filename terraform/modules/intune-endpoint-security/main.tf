locals {
  display_prefix = "${var.name_prefix}-${var.environment}"

  # Audit-first for non-standard rules surfaces line-of-business conflicts before enforcement.
  asr_rules = merge({
    blockabuseofexploitedvulnerablesigneddrivers                               = "block"
    blockcredentialstealingfromwindowslocalsecurityauthoritysubsystem          = "block"
    blockpersistencethroughwmieventsubscription                                = "block"
    blockexecutablecontentfromemailclientandwebmail                            = "audit"
    blockallofficeapplicationsfromcreatingchildprocesses                       = "audit"
    blockofficeapplicationsfromcreatingexecutablecontent                       = "audit"
    blockofficeapplicationsfrominjectingcodeintootherprocesses                 = "audit"
    blockjavascriptorvbscriptfromlaunchingdownloadedexecutablecontent          = "audit"
    blockexecutionofpotentiallyobfuscatedscripts                               = "audit"
    blockwin32apicallsfromofficemacros                                         = "audit"
    blockexecutablefilesrunningunlesstheymeetprevalenceagetrustedlistcriterion = "audit"
    useadvancedprotectionagainstransomware                                     = "audit"
    blockprocesscreationsfrompsexecandwmicommands                              = "audit"
    blockuntrustedunsignedprocessesthatrunfromusb                              = "audit"
    blockofficecommunicationappfromcreatingchildprocesses                      = "audit"
    blockadobereaderfromcreatingchildprocesses                                 = "audit"
    blockwebshellcreationforservers                                            = "audit"
    blockrebootingmachineinsafemode                                            = "audit"
    blockuseofcopiedorimpersonatedsystemtools                                  = "audit"
  }, var.asr_rules)

  bitlocker_method = { aes_cbc_128 = 3, aes_cbc_256 = 4, xts_aes_128 = 6, xts_aes_256 = 7 }
  laps_action      = { reset = 1, reset_and_logoff = 3, reset_and_reboot = 5, reset_logoff_and_terminate = 11 }

  template_vars = {
    antivirus = {
      cloud_block_level  = { default = 0, high = 2, high_plus = 4, zero_tolerance = 6 }[var.antivirus.cloud_block_level]
      network_protection = { block = 1, audit = 2 }[var.antivirus.network_protection]
      sample_submission  = { safe = 1, all = 3 }[var.antivirus.sample_submission]
    }
    firewall = {
      public_allow_local_rule_merge = tostring(var.firewall_public_allow_local_rule_merge)
    }
    asr = {
      asr_rules = { for r, m in local.asr_rules : r => m if m != "off" }
    }
    edr = {}
    bitlocker = {
      os_drive_method        = local.bitlocker_method[var.bitlocker.os_drive_method]
      fixed_drive_method     = local.bitlocker_method[var.bitlocker.fixed_drive_method]
      removable_drive_method = local.bitlocker_method[var.bitlocker.removable_drive_method]
    }
    laps = {
      password_age_days                     = var.laps.password_age_days
      password_length                       = var.laps.password_length
      password_complexity                   = var.laps.password_complexity
      post_authentication_action            = local.laps_action[var.laps.post_authentication_action]
      post_authentication_reset_delay_hours = var.laps.post_authentication_reset_delay_hours
    }
  }

  policies = {
    for k in var.policies : k => jsondecode(templatefile("${path.module}/templates/${k}.json.tftpl", merge(local.template_vars[k], {
      name               = "${local.display_prefix}-es-${k}"
      role_scope_tag_ids = var.role_scope_tag_ids
    })))
  }

  assignments = {
    for k, a in var.assignments : k => concat(
      [for g in a.include_group_ids : { target = { "@odata.type" = "#microsoft.graph.groupAssignmentTarget", groupId = g } }],
      [for g in a.exclude_group_ids : { target = { "@odata.type" = "#microsoft.graph.exclusionGroupAssignmentTarget", groupId = g } }],
    ) if contains(keys(local.policies), k)
  }
}

# beta: templateReference binding to endpoint security templates exists only on beta.
resource "msgraph_resource" "policy" {
  for_each = local.policies

  url           = "deviceManagement/configurationPolicies"
  api_version   = "beta"
  update_method = "PUT"
  body          = each.value

  response_export_values = {
    id   = "id"
    name = "name"
  }
}

resource "msgraph_resource_action" "assign" {
  for_each = local.assignments

  resource_url = msgraph_resource.policy[each.key].resource_url
  action       = "assign"
  method       = "POST"
  api_version  = "beta"
  body         = { assignments = each.value }
}
