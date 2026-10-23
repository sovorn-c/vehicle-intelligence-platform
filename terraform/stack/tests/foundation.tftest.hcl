variables {
  pipeline_image = "ghcr.io/sovorn-c/x@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  mcp_image      = "ghcr.io/sovorn-c/x@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  agent_image    = "ghcr.io/sovorn-c/x@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
}

mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "11111111-1111-1111-1111-111111111111"
      object_id       = "22222222-2222-2222-2222-222222222222"
      subscription_id = "33333333-3333-3333-3333-333333333333"
    }
  }

  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-demo"
    }
  }

  mock_resource "azurerm_virtual_network" {
    defaults = {
      id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-demo/providers/Microsoft.Network/virtualNetworks/vnet-vip-demo"
    }
  }

  mock_resource "azurerm_subnet" {
    defaults = {
      id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-demo/providers/Microsoft.Network/virtualNetworks/vnet-vip-demo/subnets/snet"
    }
  }

  mock_resource "azurerm_private_dns_zone" {
    defaults = {
      id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-demo/providers/Microsoft.Network/privateDnsZones/x.private.postgres.database.azure.com"
    }
  }

  mock_resource "azurerm_postgresql_flexible_server" {
    defaults = {
      id   = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-demo/providers/Microsoft.DBforPostgreSQL/flexibleServers/psql-vip-abcde"
      fqdn = "psql-vip-abcde.postgres.database.azure.com"
    }
  }

  mock_resource "azurerm_log_analytics_workspace" {
    defaults = {
      id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-demo/providers/Microsoft.OperationalInsights/workspaces/log-vip-abcde"
    }
  }

  mock_resource "azurerm_key_vault" {
    defaults = {
      id        = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-demo/providers/Microsoft.KeyVault/vaults/kv-vip-abcde"
      vault_uri = "https://kv-vip-abcde.vault.azure.net/"
    }
  }

  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-demo/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-vip"
      client_id    = "99999999-9999-9999-9999-999999999999"
      principal_id = "88888888-8888-8888-8888-888888888888"
    }
  }

  mock_resource "azurerm_key_vault_secret" {
    defaults = {
      versionless_id = "https://kv-vip-abcde.vault.azure.net/secrets/example"
    }
  }

  mock_resource "azurerm_cognitive_account" {
    defaults = {
      id       = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-demo/providers/Microsoft.CognitiveServices/accounts/oai-vip-abcde"
      endpoint = "https://oai-vip-abcde.openai.azure.com/"
    }
  }

  mock_resource "azurerm_container_app_environment" {
    defaults = {
      id             = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-demo/providers/Microsoft.App/managedEnvironments/cae-vip-demo"
      default_domain = "example.australiaeast.azurecontainerapps.io"
    }
  }
}

mock_provider "random" {}

run "postgres_is_private_and_pgvector_enabled" {
  command = plan

  assert {
    condition     = azurerm_postgresql_flexible_server.main.public_network_access_enabled == false
    error_message = "Postgres must not be public."
  }
  assert {
    condition     = azurerm_postgresql_flexible_server.main.version == "16"
    error_message = "Postgres must be v16."
  }
  assert {
    condition     = azurerm_postgresql_flexible_server.main.sku_name == "B_Standard_B1ms"
    error_message = "Unexpected Postgres SKU."
  }
  assert {
    condition     = azurerm_postgresql_flexible_server.main.storage_mb == 32768
    error_message = "Unexpected Postgres storage."
  }
  assert {
    condition     = azurerm_postgresql_flexible_server_configuration.extensions.name == "azure.extensions" && azurerm_postgresql_flexible_server_configuration.extensions.value == "VECTOR"
    error_message = "azure.extensions must be VECTOR."
  }
}

run "databases_are_separate" {
  command = plan

  assert {
    condition     = toset([azurerm_postgresql_flexible_server_database.pipeline.name, azurerm_postgresql_flexible_server_database.agent.name]) == toset(["agent", "pipeline"])
    error_message = "Databases must be agent and pipeline."
  }
}

run "database_urls_are_psycopg_tls" {
  command = apply

  assert {
    condition     = startswith(azurerm_key_vault_secret.pipeline_database_url.value, "postgresql+psycopg://vipadmin:") && endswith(azurerm_key_vault_secret.pipeline_database_url.value, "/pipeline?sslmode=require")
    error_message = "Bad pipeline database URL."
  }
  assert {
    condition     = startswith(azurerm_key_vault_secret.agent_database_url.value, "postgresql+psycopg://vipadmin:") && endswith(azurerm_key_vault_secret.agent_database_url.value, "/agent?sslmode=require")
    error_message = "Bad agent database URL."
  }
  assert {
    condition     = random_password.pg_admin.special == false
    error_message = "pg admin password must not contain special characters."
  }
}

run "agent_secrets_meet_production_validation" {
  command = plan

  assert {
    condition = alltrue([
      for p in [
        random_password.agent_requester_token,
        random_password.agent_reviewer_token,
        random_password.agent_operator_token,
        random_password.agent_maintainer_token,
        random_password.agent_snapshot_integrity_secret,
      ] : p.length >= 48 && p.special == false
    ])
    error_message = "Agent secrets must be >= 48 chars with no specials."
  }
}

run "key_vault_is_rbac_and_suffixed" {
  command = plan

  assert {
    condition     = azurerm_key_vault.main.rbac_authorization_enabled == true
    error_message = "Key Vault must use RBAC."
  }
  assert {
    condition     = azurerm_key_vault.main.purge_protection_enabled == false
    error_message = "Purge protection must be off."
  }
  assert {
    condition     = strcontains(azurerm_key_vault.main.name, random_string.suffix.result)
    error_message = "Key Vault name must contain the suffix."
  }
}

run "aca_subnet_is_delegated_slash_27" {
  command = plan

  assert {
    condition     = one(azurerm_subnet.aca.address_prefixes) == "10.40.0.0/27"
    error_message = "ACA subnet must be 10.40.0.0/27."
  }
  assert {
    condition     = one(azurerm_subnet.aca.delegation).service_delegation[0].name == "Microsoft.App/environments"
    error_message = "ACA subnet must be delegated to Microsoft.App/environments."
  }
}
