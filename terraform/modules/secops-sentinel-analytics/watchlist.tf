resource "azurerm_sentinel_watchlist" "break_glass" {
  name                       = "BreakGlassAccounts"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  display_name               = "Break-glass accounts"
  description                = "Emergency access accounts. Any sign-in is an incident."
  item_search_key            = "UserPrincipalName"
  labels                     = ["identity", "tier0"]
}

resource "azurerm_sentinel_watchlist_item" "break_glass" {
  for_each = var.break_glass_upns

  watchlist_id = azurerm_sentinel_watchlist.break_glass.id
  properties = {
    UserPrincipalName = lower(each.value)
  }
}
