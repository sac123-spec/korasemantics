variable "parameter_prefix" {
  description = "Prefix to prepend to all parameter names"
  type        = string
  default     = ""
}

variable "parameters" {
  description = "Map of parameter names to definitions"
  type = map(object({
    value       = string
    type        = optional(string, "String")
    description = optional(string)
    tier        = optional(string, "Standard")
    overwrite   = optional(bool, true)
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to the SSM parameters"
  type        = map(string)
  default     = {}
}
