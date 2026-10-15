variable "name" {
  description = "The app's name, lowercase letters, digits and hyphens. Every resource is named after it and the stage."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}$", var.name))
    error_message = "name is lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "stage" {
  description = "Which stage on the path to production this is: dev, sit, uat, staging, perf or prod."
  type        = string

  validation {
    condition     = contains(["dev", "sit", "uat", "staging", "perf", "prod"], var.stage)
    error_message = "stage is one of dev, sit, uat, staging, perf, prod."
  }
}

variable "tags" {
  description = "Tags added to every resource, beside the ones this module sets."
  type        = map(string)
  default     = {}
}

variable "domain_name" {
  description = "The full name to answer on."
  type        = string
}

variable "zone_id" {
  description = "The zone the name is in, one the platform team manages."
  type        = string
}

variable "target_domain_name" {
  description = "The address the name points at."
  type        = string
}

variable "target_zone_id" {
  description = "The zone of the address the name points at."
  type        = string
}
