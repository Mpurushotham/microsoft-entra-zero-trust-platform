variable "name_prefix" {
  type = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,9}$", var.name_prefix))
    error_message = "name_prefix must be 2-10 lowercase alphanumeric characters starting with a letter."
  }
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "ip_locations" {
  description = "IP-range named locations keyed by purpose. Display name becomes <prefix>-<env>-nl-<key>."
  type = map(object({
    ip_ranges = list(string)
    trusted   = optional(bool, false)
  }))
  default = {}

  validation {
    condition     = alltrue(flatten([for l in values(var.ip_locations) : [for r in l.ip_ranges : can(cidrhost(r, 0))]]))
    error_message = "Every ip_ranges entry must be a valid IPv4 or IPv6 CIDR."
  }
}

variable "country_locations" {
  description = "Country named locations keyed by purpose. Display name becomes <prefix>-<env>-nl-<key>."
  type = map(object({
    countries_and_regions                 = list(string)
    include_unknown_countries_and_regions = optional(bool, false)
    country_lookup_method                 = optional(string, "clientIpAddress")
  }))
  default = {}

  validation {
    condition     = alltrue(flatten([for l in values(var.country_locations) : [for c in l.countries_and_regions : can(regex("^[A-Z]{2}$", c))]]))
    error_message = "countries_and_regions must be ISO 3166-1 alpha-2 codes."
  }

  validation {
    condition     = alltrue([for l in values(var.country_locations) : contains(["clientIpAddress", "authenticatorAppGps"], l.country_lookup_method)])
    error_message = "country_lookup_method must be clientIpAddress or authenticatorAppGps."
  }

  validation {
    condition     = length(setintersection(keys(var.ip_locations), keys(var.country_locations))) == 0
    error_message = "Keys must be unique across ip_locations and country_locations."
  }
}
