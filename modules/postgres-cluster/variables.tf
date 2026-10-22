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

variable "subnet_group_name" {
  description = "The stage's database subnet group, in the private network."
  type        = string
}

variable "security_group_ids" {
  description = "Who may connect."
  type        = list(string)
}

variable "instance_class" {
  description = "The instance size."
  type        = string
  default     = "db.r6g.large"
}

variable "permissions_boundary_arn" {
  description = "The platform's permissions boundary, which every function at Juniper Mutual carries; the one-time setup function carries it too."
  type        = string
  default     = null
}
