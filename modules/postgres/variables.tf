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
  description = "The instance size. Signing in with the app's own identity takes memory on the database, so the smallest size is not enough for it."
  type        = string
  default     = "db.t4g.small"
}

variable "master_password" {
  description = "Leave unset: the platform makes and keeps the password. Only for restoring an old snapshot by hand."
  type        = string
  default     = null
  sensitive   = true
}

variable "permissions_boundary_arn" {
  description = "The platform's permissions boundary, which every function at Juniper Mutual carries; the one-time setup function carries it too."
  type        = string
  default     = null
}
