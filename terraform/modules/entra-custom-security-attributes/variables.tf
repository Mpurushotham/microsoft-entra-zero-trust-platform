variable "attribute_sets" {
  description = "Custom security attribute sets keyed by set name, each with its attribute definitions."
  type = map(object({
    description            = string
    max_attributes_per_set = optional(number, 25)
    attributes = optional(map(object({
      description                 = string
      type                        = optional(string, "String")
      is_collection               = optional(bool, false)
      is_searchable               = optional(bool, true)
      use_pre_defined_values_only = optional(bool, false)
    })), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for k in keys(var.attribute_sets) : can(regex("^[A-Za-z][A-Za-z0-9]{0,31}$", k))])
    error_message = "Attribute set names must be 1-32 alphanumeric characters starting with a letter, no spaces."
  }

  validation {
    condition     = alltrue(flatten([for s in values(var.attribute_sets) : [for a in values(s.attributes) : contains(["String", "Integer", "Boolean"], a.type)]]))
    error_message = "Attribute type must be String, Integer or Boolean."
  }
}
