resource "azurerm_cognitive_account" "openai" {
  name                  = "oai-${var.name_prefix}-${local.suffix}"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  kind                  = "OpenAI"
  sku_name              = "S0"
  custom_subdomain_name = "oai-${var.name_prefix}-${local.suffix}"
  local_auth_enabled    = false
}

resource "azurerm_cognitive_deployment" "chat" {
  name                 = "chat"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = var.openai_model_name
    version = var.openai_model_version
  }

  sku {
    name     = "Standard"
    capacity = var.openai_capacity
  }
}
