locals {
  display_prefix = "${var.name_prefix}-${var.environment}"

  # Each data protection framework level inherits the one below it.
  level_1 = {
    offline_access_check        = "PT720M"
    online_access_check         = "PT30M"
    offline_wipe                = "P90D"
    backup_blocked              = false
    inbound_sources             = "allApps"
    outbound_destinations       = "allApps"
    clipboard_level             = "allApps"
    save_as_blocked             = false
    storage_locations           = ["oneDriveForBusiness", "sharePoint", "localStorage", "photoLibrary"]
    print_blocked               = false
    managed_browser_required    = false
    managed_browser             = "notConfigured"
    pin_min_length              = 4
    simple_pin_blocked          = false
    app_pin_off_with_device_pin = true
    third_party_keyboards       = false
    screen_capture_blocked      = false
    notification_restriction    = "allow"
    max_device_threat_level     = "notConfigured"
  }
  level_2 = merge(local.level_1, {
    backup_blocked           = true
    outbound_destinations    = "managedApps"
    clipboard_level          = "managedAppsWithPasteIn"
    save_as_blocked          = true
    storage_locations        = ["oneDriveForBusiness", "sharePoint"]
    print_blocked            = true
    managed_browser_required = true
    managed_browser          = "microsoftEdge"
    third_party_keyboards    = true
    screen_capture_blocked   = true
  })
  level_3 = merge(local.level_2, {
    inbound_sources             = "managedApps"
    pin_min_length              = 6
    simple_pin_blocked          = true
    app_pin_off_with_device_pin = false
    notification_restriction    = "blockOrganizationalData"
    max_device_threat_level     = "secured"
  })
  level = { 1 = local.level_1, 2 = local.level_2, 3 = local.level_3 }[var.protection_level]

  ios_bundle_ids = coalescelist(var.ios_bundle_ids, [
    "com.microsoft.office.outlook",
    "com.microsoft.skype.teams",
    "com.microsoft.office.word",
    "com.microsoft.office.excel",
    "com.microsoft.office.powerpoint",
    "com.microsoft.officemobile",
    "com.microsoft.skydrive",
    "com.microsoft.sharepoint",
    "com.microsoft.msedge",
    "com.microsoft.onenote",
  ])

  android_package_ids = coalescelist(var.android_package_ids, [
    "com.microsoft.office.outlook",
    "com.microsoft.teams",
    "com.microsoft.office.word",
    "com.microsoft.office.excel",
    "com.microsoft.office.powerpoint",
    "com.microsoft.office.officehubrow",
    "com.microsoft.skydrive",
    "com.microsoft.sharepoint",
    "com.microsoft.emmx",
    "com.microsoft.office.onenote",
  ])

  policies = {
    for p in var.platforms : p => jsondecode(templatefile("${path.module}/templates/${p}.json.tftpl", merge(local.level, {
      display_name       = "${local.display_prefix}-app-protection-${p}-level${var.protection_level}"
      level_number       = var.protection_level
      role_scope_tag_ids = var.role_scope_tag_ids
      minimum_os_version = var.minimum_os_versions[p]
    })))
  }

  target_apps = {
    ios = [for id in local.ios_bundle_ids : {
      "@odata.type"       = "#microsoft.graph.managedMobileApp"
      mobileAppIdentifier = { "@odata.type" = "#microsoft.graph.iosMobileAppIdentifier", bundleId = id }
    }]
    android = [for id in local.android_package_ids : {
      "@odata.type"       = "#microsoft.graph.managedMobileApp"
      mobileAppIdentifier = { "@odata.type" = "#microsoft.graph.androidMobileAppIdentifier", packageId = id }
    }]
  }

  collection = {
    ios     = "deviceAppManagement/iosManagedAppProtections"
    android = "deviceAppManagement/androidManagedAppProtections"
  }

  assignments = concat(
    [for g in var.include_group_ids : { target = { "@odata.type" = "#microsoft.graph.groupAssignmentTarget", groupId = g } }],
    [for g in var.exclude_group_ids : { target = { "@odata.type" = "#microsoft.graph.exclusionGroupAssignmentTarget", groupId = g } }],
  )
}

# beta: roleScopeTagIds, appGroupType and several level 2/3 controls are beta-only.
resource "msgraph_resource" "policy" {
  for_each = local.policies

  url         = local.collection[each.key]
  api_version = "beta"
  body        = each.value

  response_export_values = {
    id = "id"
  }
}

resource "msgraph_resource_action" "target_apps" {
  for_each = local.policies

  resource_url = msgraph_resource.policy[each.key].resource_url
  action       = "targetApps"
  method       = "POST"
  api_version  = "beta"
  body = {
    appGroupType = "selectedPublicApps"
    apps         = local.target_apps[each.key]
  }
}

resource "msgraph_resource_action" "assign" {
  for_each = local.policies

  resource_url = msgraph_resource.policy[each.key].resource_url
  action       = "assign"
  method       = "POST"
  api_version  = "beta"
  body         = { assignments = local.assignments }

  depends_on = [msgraph_resource_action.target_apps]
}
