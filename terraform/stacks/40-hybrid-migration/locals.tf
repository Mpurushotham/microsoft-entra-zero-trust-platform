locals {
  external_group_names = toset(flatten([
    for app in values(var.migrated_applications) : app.assignment_group_display_names
  ]))
}
