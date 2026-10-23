resource "azurerm_user_assigned_identity" "pipeline" {
  name                = "id-${var.name_prefix}-pipeline"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_user_assigned_identity" "mcp" {
  name                = "id-${var.name_prefix}-mcp"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_user_assigned_identity" "agent" {
  name                = "id-${var.name_prefix}-agent"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# MCP reads no secrets, so it gets no Key Vault role.
resource "azurerm_role_assignment" "pipeline_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.pipeline.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "agent_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.agent.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "agent_openai" {
  scope                = azurerm_cognitive_account.openai.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.agent.principal_id
  principal_type       = "ServicePrincipal"
}
