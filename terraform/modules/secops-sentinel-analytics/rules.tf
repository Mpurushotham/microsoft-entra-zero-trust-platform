locals {
  account_ip_entities = [
    { entity_type = "Account", identifier = "FullName", column_name = "AccountUpn" },
    { entity_type = "IP", identifier = "Address", column_name = "IPAddress" },
  ]

  rules = {
    break-glass-sign-in = {
      display_name    = "Break-glass account sign-in"
      description     = "Any interactive or non-interactive sign-in attempt by an emergency access account. These accounts are excluded from Conditional Access, so every use must be explained."
      severity        = "High"
      query_frequency = "PT5M"
      query_period    = "PT5M"
      tactics         = ["InitialAccess", "Persistence", "PrivilegeEscalation"]
      techniques      = ["T1078"]
      query = templatefile("${path.module}/templates/break-glass-sign-in.kql.tftpl", {
        watchlist_alias = azurerm_sentinel_watchlist.break_glass.name
      })
      entities = local.account_ip_entities
    }
    conditional-access-change = {
      display_name    = "Conditional Access policy changed outside the pipeline"
      description     = "A Conditional Access policy was created, updated or deleted by an identity other than the deployment pipeline. Deletions always alert."
      severity        = "Medium"
      query_frequency = "PT15M"
      query_period    = "PT15M"
      tactics         = ["DefenseEvasion", "Persistence"]
      techniques      = ["T1562", "T1556"]
      query = templatefile("${path.module}/templates/conditional-access-change.kql.tftpl", {
        trusted_actors = jsonencode(sort(tolist(var.trusted_automation_names)))
      })
      entities = local.account_ip_entities
    }
    pim-activation-outside-hours = {
      display_name    = "PIM role activation outside business hours"
      description     = "A privileged role or PIM for Groups activation completed outside configured working hours."
      severity        = "Medium"
      query_frequency = "PT1H"
      query_period    = "PT1H"
      tactics         = ["PrivilegeEscalation"]
      techniques      = ["T1078", "T1098"]
      query = templatefile("${path.module}/templates/pim-activation-outside-hours.kql.tftpl", {
        start_hour       = var.business_hours.start_hour
        end_hour         = var.business_hours.end_hour
        utc_offset_hours = var.business_hours.utc_offset_hours
        workdays         = jsonencode(var.business_hours.workdays)
      })
      entities = local.account_ip_entities
    }
    mfa-fatigue = {
      display_name    = "MFA fatigue: repeated denied or unanswered prompts"
      description     = "Many MFA prompts denied, unanswered or reported as fraud for one user in an hour, a sign of push bombing after password compromise."
      severity        = "High"
      query_frequency = "PT15M"
      query_period    = "PT1H"
      tactics         = ["CredentialAccess"]
      techniques      = ["T1621"]
      query = templatefile("${path.module}/templates/mfa-fatigue.kql.tftpl", {
        threshold = var.mfa_fatigue_threshold
      })
      entities = local.account_ip_entities
    }
    legacy-auth-success = {
      display_name    = "Successful legacy authentication sign-in"
      description     = "A sign-in succeeded over a legacy protocol that cannot perform MFA. The Conditional Access baseline blocks these, so success means a gap or an excluded account."
      severity        = "Medium"
      query_frequency = "PT1H"
      query_period    = "PT1H"
      tactics         = ["InitialAccess", "DefenseEvasion"]
      techniques      = ["T1078"]
      query           = file("${path.module}/templates/legacy-auth-success.kql")
      entities        = local.account_ip_entities
    }
    federated-domain-change = {
      display_name    = "Domain federation or authentication changed"
      description     = "A domain was federated, its federation settings changed or a new domain was verified. Rogue federation trusts let an attacker mint tokens for any user (T1484.002)."
      severity        = "High"
      query_frequency = "PT15M"
      query_period    = "PT15M"
      tactics         = ["DefenseEvasion", "PrivilegeEscalation", "Persistence"]
      techniques      = ["T1484"]
      query           = file("${path.module}/templates/federated-domain-change.kql")
      entities = concat(local.account_ip_entities, [
        { entity_type = "DNS", identifier = "DomainName", column_name = "DomainName" },
      ])
    }
  }
}

resource "azurerm_sentinel_alert_rule_scheduled" "this" {
  for_each = local.rules

  name                       = "${var.name_prefix}-${each.key}"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  display_name               = "[${upper(var.name_prefix)}] ${each.value.display_name}"
  description                = each.value.description
  severity                   = each.value.severity
  enabled                    = !contains(var.disabled_rules, each.key)
  query                      = each.value.query
  query_frequency            = each.value.query_frequency
  query_period               = each.value.query_period
  trigger_operator           = "GreaterThan"
  trigger_threshold          = 0
  tactics                    = each.value.tactics
  techniques                 = each.value.techniques

  event_grouping {
    aggregation_method = "AlertPerResult"
  }

  incident {
    create_incident_enabled = true

    grouping {
      enabled                 = true
      lookback_duration       = "PT5H"
      entity_matching_method  = "Selected"
      by_entities             = ["Account"]
      reopen_closed_incidents = false
    }
  }

  alert_details_override {
    severity_column_name = "AlertSeverity"
  }

  dynamic "entity_mapping" {
    for_each = each.value.entities

    content {
      entity_type = entity_mapping.value.entity_type

      field_mapping {
        identifier  = entity_mapping.value.identifier
        column_name = entity_mapping.value.column_name
      }
    }
  }
}
