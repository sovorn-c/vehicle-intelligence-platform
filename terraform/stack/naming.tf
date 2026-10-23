resource "random_string" "suffix" {
  length  = 5
  lower   = true
  numeric = true
  upper   = false
  special = false
}

locals {
  suffix  = random_string.suffix.result
  rg_name = "rg-${var.name_prefix}-demo"
  kv_name = "kv-${var.name_prefix}-${local.suffix}"
  pg_name = "psql-${var.name_prefix}-${local.suffix}"
}

resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.location
}
