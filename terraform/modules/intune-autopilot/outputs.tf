output "deployment_profile_ids" {
  value = { for k, p in msgraph_resource.deployment_profile : k => p.id }
}

output "enrollment_status_page_id" {
  value = msgraph_resource.enrollment_status_page.id
}

output "store_app_ids" {
  value = { for k, a in msgraph_resource.store_app : k => a.id }
}

output "android_fully_managed_profile_id" {
  value = one(msgraph_resource.android_fully_managed[*].id)
}

output "apple_ade_profile_id" {
  value = one(msgraph_resource.apple_ade_profile[*].id)
}

output "android_zero_touch_dpc_extras" {
  description = "DPC extras JSON for the Android zero-touch portal configuration. Replace the token placeholder with the profile token from the Intune admin center."
  value = jsonencode({
    "android.app.extra.PROVISIONING_DEVICE_ADMIN_COMPONENT_NAME"            = "com.google.android.apps.work.clouddpc/.receivers.CloudDeviceAdminReceiver"
    "android.app.extra.PROVISIONING_DEVICE_ADMIN_SIGNATURE_CHECKSUM"        = "I5YvS0O5hXY46mb01BlRjq4oJJGs2kuUcHvVkAPEXlg"
    "android.app.extra.PROVISIONING_DEVICE_ADMIN_PACKAGE_DOWNLOAD_LOCATION" = "https://play.google.com/managed/downloadManagingApp?identifier=setup"
    "android.app.extra.PROVISIONING_ADMIN_EXTRAS_BUNDLE" = {
      "com.google.android.apps.work.clouddpc.EXTRA_ENROLLMENT_TOKEN" = "<enrollment-token>"
    }
  })
}
