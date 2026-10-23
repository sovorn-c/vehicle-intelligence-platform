data "azurerm_client_config" "current" {}

resource "random_password" "agent_requester_token" {
  length  = 48
  special = false
}

resource "random_password" "agent_reviewer_token" {
  length  = 48
  special = false
}

resource "random_password" "agent_operator_token" {
  length  = 48
  special = false
}

resource "random_password" "agent_maintainer_token" {
  length  = 48
  special = false
}

resource "random_password" "agent_snapshot_integrity_secret" {
  length  = 48
  special = false
}

resource "azurerm_key_vault" "main" {
  name                       = local.kv_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
}

resource "azurerm_role_assignment" "deployer_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

locals {
  pg_url_base = "postgresql+psycopg://${azurerm_postgresql_flexible_server.main.administrator_login}:${random_password.pg_admin.result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432"
}

resource "azurerm_key_vault_secret" "pg_admin_password" {
  name         = "pg-admin-password"
  value        = random_password.pg_admin.result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.deployer_secrets_officer]
}

resource "azurerm_key_vault_secret" "pipeline_database_url" {
  name         = "pipeline-database-url"
  value        = "${local.pg_url_base}/${azurerm_postgresql_flexible_server_database.pipeline.name}?sslmode=require"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.deployer_secrets_officer]
}

resource "azurerm_key_vault_secret" "agent_database_url" {
  name         = "agent-database-url"
  value        = "${local.pg_url_base}/${azurerm_postgresql_flexible_server_database.agent.name}?sslmode=require"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.deployer_secrets_officer]
}

resource "azurerm_key_vault_secret" "agent_requester_token" {
  name         = "agent-requester-token"
  value        = random_password.agent_requester_token.result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.deployer_secrets_officer]
}

resource "azurerm_key_vault_secret" "agent_reviewer_token" {
  name         = "agent-reviewer-token"
  value        = random_password.agent_reviewer_token.result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.deployer_secrets_officer]
}

resource "azurerm_key_vault_secret" "agent_operator_token" {
  name         = "agent-operator-token"
  value        = random_password.agent_operator_token.result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.deployer_secrets_officer]
}

resource "azurerm_key_vault_secret" "agent_maintainer_token" {
  name         = "agent-maintainer-token"
  value        = random_password.agent_maintainer_token.result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.deployer_secrets_officer]
}

resource "azurerm_key_vault_secret" "agent_snapshot_integrity_secret" {
  name         = "agent-snapshot-integrity-secret"
  value        = random_password.agent_snapshot_integrity_secret.result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.deployer_secrets_officer]
}

locals {
  secret_ids = {
    "pg-admin-password"               = azurerm_key_vault_secret.pg_admin_password.versionless_id
    "pipeline-database-url"           = azurerm_key_vault_secret.pipeline_database_url.versionless_id
    "agent-database-url"              = azurerm_key_vault_secret.agent_database_url.versionless_id
    "agent-requester-token"           = azurerm_key_vault_secret.agent_requester_token.versionless_id
    "agent-reviewer-token"            = azurerm_key_vault_secret.agent_reviewer_token.versionless_id
    "agent-operator-token"            = azurerm_key_vault_secret.agent_operator_token.versionless_id
    "agent-maintainer-token"          = azurerm_key_vault_secret.agent_maintainer_token.versionless_id
    "agent-snapshot-integrity-secret" = azurerm_key_vault_secret.agent_snapshot_integrity_secret.versionless_id
  }
}
