variable "location" {
  type        = string
  description = "Azure region for the state storage and deployer identity."
  default     = "australiaeast"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository (owner/name) allowed to log in through OIDC."
  default     = "sovorn-c/vehicle-intelligence-platform"
}

variable "github_environment" {
  type        = string
  description = "GitHub environment whose workflows may assume the deployer identity."
  default     = "azure"
}

variable "budget_amount" {
  type        = number
  description = "Monthly subscription budget in the subscription currency."
  default     = 25

  validation {
    condition     = var.budget_amount > 0 && var.budget_amount <= 200
    error_message = "budget_amount must be greater than 0 and at most 200."
  }
}

variable "budget_contact_email" {
  type        = string
  description = "Address that receives budget notifications."

  validation {
    condition     = strcontains(var.budget_contact_email, "@")
    error_message = "budget_contact_email must be an email address."
  }
}

variable "budget_start_date" {
  type        = string
  description = "Budget start, RFC 3339, first day of a month (for example 2026-11-01T00:00:00Z)."

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-01T00:00:00Z$", var.budget_start_date))
    error_message = "budget_start_date must be the first day of a month at 00:00:00Z."
  }
}
