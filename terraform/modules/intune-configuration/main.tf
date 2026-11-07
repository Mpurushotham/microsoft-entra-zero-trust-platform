locals {
  display_prefix = "${var.name_prefix}-${var.environment}"

  dma_guard_option = { block_all = 0, after_login = 1, allow_all = 2 }[var.dma_guard_policy]

  # Choice settings as definitionId => option suffix; the option itemId is "<definitionId>_<suffix>".
  catalog = {
    credential_guard = {
      description = "Virtualization-based security and Credential Guard, aligned with the Windows security baseline."
      settings = {
        device_vendor_msft_policy_config_deviceguard_enablevirtualizationbasedsecurity = "1"
        device_vendor_msft_policy_config_deviceguard_requireplatformsecurityfeatures   = var.vbs_require_dma_protection ? "3" : "1"
        device_vendor_msft_policy_config_deviceguard_lsacfgflags                       = var.credential_guard_uefi_lock ? "1" : "2"
      }
    }
    os_hardening = {
      description = "Windows security baseline complements: SmartScreen, Kernel DMA Protection, local account and Wi-Fi Sense hardening."
      settings = {
        device_vendor_msft_policy_config_smartscreen_enablesmartscreeninshell                                                         = "1"
        device_vendor_msft_policy_config_smartscreen_preventoverrideforfilesinshell                                                   = "1"
        device_vendor_msft_policy_config_dmaguard_deviceenumerationpolicy                                                             = tostring(local.dma_guard_option)
        device_vendor_msft_policy_config_localpoliciessecurityoptions_accounts_limitlocalaccountuseofblankpasswordstoconsolelogononly = "1"
        device_vendor_msft_policy_config_wifi_allowautoconnecttowifisensehotspots                                                     = "0"
      }
    }
  }

  policies = {
    for k in var.policies : k => jsondecode(templatefile("${path.module}/templates/settings-catalog.json.tftpl", {
      name               = "${local.display_prefix}-win-${replace(k, "_", "-")}"
      description        = local.catalog[k].description
      role_scope_tag_ids = var.role_scope_tag_ids
      settings           = local.catalog[k].settings
    }))
  }

  assignments = {
    for k, a in var.assignments : k => concat(
      [for g in a.include_group_ids : { target = { "@odata.type" = "#microsoft.graph.groupAssignmentTarget", groupId = g } }],
      [for g in a.exclude_group_ids : { target = { "@odata.type" = "#microsoft.graph.exclusionGroupAssignmentTarget", groupId = g } }],
    ) if contains(keys(local.policies), k)
  }
}

# Settings are a navigation property that Intune only replaces via PUT (beta-only endpoint).
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
