data "azuread_domains" "initial" {
  only_initial = true
}

locals {
  # The *.onmicrosoft.com domain never depends on federation, DNS or on-premises sync.
  initial_domain = data.azuread_domains.initial.domains[0].domain_name

  accounts = {
    for idx, alias in var.account_aliases : alias => {
      upn          = "${alias}@${local.initial_domain}"
      display_name = format("Emergency Access Account %02d", idx + 1)
    }
  }

  global_administrator_template_id = "62e90394-69f5-4237-9190-012177145e10"
}

resource "random_password" "this" {
  for_each = local.accounts

  length           = var.password_length
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 4
  min_upper        = 4
  min_numeric      = 4
  min_special      = 4
}

resource "azuread_user" "this" {
  for_each = local.accounts

  user_principal_name         = each.value.upn
  display_name                = each.value.display_name
  mail_nickname               = each.key
  password                    = random_password.this[each.key].result
  force_password_change       = false
  disable_password_expiration = true
  account_enabled             = true
  show_in_address_list        = false
  usage_location              = var.usage_location

  lifecycle {
    # Password is custodian-held after hand-off; rotation uses -replace (see README).
    ignore_changes = [password]
  }
}

resource "azuread_directory_role_assignment" "global_administrator" {
  for_each = var.assign_global_administrator ? local.accounts : {}

  role_id             = local.global_administrator_template_id
  principal_object_id = azuread_user.this[each.key].object_id
}
