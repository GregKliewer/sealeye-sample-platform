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

variable "package_path" {
  description = "The zipped app, built once by the pipeline and promoted unchanged."
  type        = string
}

variable "handler" {
  description = "The function the platform calls."
  type        = string
  default     = "index.handler"
}

variable "environment" {
  description = "Settings the app reads from its environment, names to values. Never a secret: put those in the secrets module."
  type        = map(string)
  default     = {}
}

variable "permissions_boundary_arn" {
  description = "The platform's permissions boundary, which every function at Juniper Mutual carries."
  type        = string
}

variable "policy_arns" {
  description = "Policies the app's role is given: what it reads and writes, from each module's access_policy_arn output. Never a policy written by hand."
  type        = list(string)
  default     = []
}

variable "secret_arns" {
  description = "Secrets the app may read while it runs, from the secrets module. Never a database's master password: an app signs in to its database with its own identity."
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "The stage's private subnets, only when the app uses something in the private network, such as a database. Empty: the app runs outside the network."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "The stage's apps security group, which the databases admit; given with subnet_ids, and empty with it."
  type        = list(string)
  default     = []
}
