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

variable "vpc_id" {
  description = "The stage's network."
  type        = string
}

variable "subnet_ids" {
  description = "The stage's private subnets."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Who may call the app."
  type        = list(string)
}

variable "certificate_arn" {
  description = "The stage's internal certificate."
  type        = string
}

variable "target_port" {
  description = "The port the app listens on."
  type        = number
  default     = 8080
}
