# entra-named-locations

Conditional Access named locations (Network assignments): trusted corporate egress
ranges and country lists used for allow/block decisions.

## Guidance applied

- Mark only egress ranges you control as `trusted`. Trusted locations lower the risk
  score in Entra ID Protection and are excluded from some policies (`AllTrusted`).
- Country locations use `clientIpAddress` lookup by default. `authenticatorAppGps`
  requires the Microsoft Authenticator app and prompts users for location consent.
- Location is a signal, not an authentication factor: never use a trusted location to
  skip MFA for administrators.

## Inputs

| Name | Type | Default |
|---|---|---|
| `name_prefix` | string | required |
| `environment` | string (`dev`/`prod`) | required |
| `ip_locations` | map(object({ ip_ranges, trusted? })) | `{}` |
| `country_locations` | map(object({ countries_and_regions, include_unknown_countries_and_regions?, country_lookup_method? })) | `{}` |

Keys must be unique across both maps.

## Outputs

| Name | Description |
|---|---|
| `locations` | `{ key => { object_id, display_name } }` |

## Example

```hcl
module "named_locations" {
  source      = "../../modules/entra-named-locations"
  name_prefix = "zt"
  environment = "prod"
  ip_locations = {
    "corporate-egress" = { ip_ranges = ["203.0.113.0/24"], trusted = true }
  }
  country_locations = {
    "blocked-countries" = { countries_and_regions = ["KP", "IR"] }
  }
}
```
