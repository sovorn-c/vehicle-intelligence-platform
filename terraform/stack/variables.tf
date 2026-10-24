variable "location" {
  description = "Azure region for every stack resource."
  type        = string
  default     = "australiaeast"
}

variable "name_prefix" {
  description = "Short lowercase prefix used in resource names."
  type        = string
  default     = "vip"

  validation {
    condition     = can(regex("^[a-z]{2,6}$", var.name_prefix))
    error_message = "name_prefix must be 2 to 6 lowercase letters."
  }
}

variable "pipeline_image" {
  description = "Digest-pinned pipeline image reference."
  type        = string

  validation {
    condition     = can(regex("^ghcr\\.io/sovorn-c/[a-z0-9._/-]+@sha256:[0-9a-f]{64}$", var.pipeline_image))
    error_message = "pipeline_image must be ghcr.io/sovorn-c/<name>@sha256:<64 hex>."
  }
}

variable "mcp_image" {
  description = "Digest-pinned MCP server image reference."
  type        = string

  validation {
    condition     = can(regex("^ghcr\\.io/sovorn-c/[a-z0-9._/-]+@sha256:[0-9a-f]{64}$", var.mcp_image))
    error_message = "mcp_image must be ghcr.io/sovorn-c/<name>@sha256:<64 hex>."
  }
}

variable "agent_image" {
  description = "Digest-pinned risk agent image reference."
  type        = string

  validation {
    condition     = can(regex("^ghcr\\.io/sovorn-c/[a-z0-9._/-]+@sha256:[0-9a-f]{64}$", var.agent_image))
    error_message = "agent_image must be ghcr.io/sovorn-c/<name>@sha256:<64 hex>."
  }
}

variable "openai_model_name" {
  description = "Azure OpenAI model name. Availability in Australia East is unverified until Phase 4."
  type        = string
  default     = "gpt-5.4-mini"
}

variable "openai_model_version" {
  description = "Azure OpenAI model version. Availability in Australia East is unverified until Phase 4."
  type        = string
  default     = "2026-03-17"
}

variable "openai_capacity" {
  description = "Azure OpenAI deployment capacity in thousands of tokens per minute. One agent draft uses about 2.2-2.4K tokens, so 1K returns 429."
  type        = number
  default     = 10

  validation {
    condition     = var.openai_capacity >= 1 && var.openai_capacity <= 10 && floor(var.openai_capacity) == var.openai_capacity
    error_message = "openai_capacity must be an integer from 1 to 10."
  }
}
