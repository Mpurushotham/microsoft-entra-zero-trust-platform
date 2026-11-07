output "rule_ids" {
  value = { for k, r in azurerm_sentinel_alert_rule_scheduled.this : k => r.id }
}

output "watchlist_alias" {
  value = azurerm_sentinel_watchlist.break_glass.name
}
