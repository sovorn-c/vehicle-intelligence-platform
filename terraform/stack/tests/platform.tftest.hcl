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

override_resource {
  override_during = plan
  target          = azurerm_user_assigned_identity.pipeline
  values = {
    id           = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-demo/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-vip-pipeline"
    client_id    = "bbbbbbbb-0000-0000-0000-000000000001"
    tenant_id    = "11111111-1111-1111-1111-111111111111"
    principal_id = "aaaaaaaa-0000-0000-0000-000000000001"
  }
}

override_resource {
  override_during = plan
  target          = azurerm_user_assigned_identity.mcp
  values = {
    id           = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-demo/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-vip-mcp"
    client_id    = "bbbbbbbb-0000-0000-0000-000000000002"
    tenant_id    = "11111111-1111-1111-1111-111111111111"
    principal_id = "aaaaaaaa-0000-0000-0000-000000000002"
  }
}

override_resource {
  override_during = plan
  target          = azurerm_user_assigned_identity.agent
  values = {
    id           = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-demo/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-vip-agent"
    client_id    = "bbbbbbbb-0000-0000-0000-000000000003"
    tenant_id    = "11111111-1111-1111-1111-111111111111"
    principal_id = "aaaaaaaa-0000-0000-0000-000000000003"
  }
}

run "openai_rejects_keys" {
  command = apply

  assert {
    condition     = azurerm_cognitive_account.openai.local_auth_enabled == false
    error_message = "OpenAI must not allow key auth."
  }
  assert {
    condition     = strcontains(azurerm_cognitive_account.openai.name, random_string.suffix.result) && azurerm_cognitive_account.openai.custom_subdomain_name == azurerm_cognitive_account.openai.name
    error_message = "OpenAI name must contain the suffix and equal its subdomain."
  }
  assert {
    condition     = azurerm_cognitive_deployment.chat.name == "chat" && azurerm_cognitive_deployment.chat.sku[0].capacity == var.openai_capacity
    error_message = "Chat deployment capacity must equal var.openai_capacity."
  }
}

run "only_agent_can_call_openai" {
  command = apply

  assert {
    condition     = azurerm_role_assignment.agent_openai.role_definition_name == "Cognitive Services OpenAI User"
    error_message = "Wrong OpenAI role."
  }
  assert {
    condition     = azurerm_role_assignment.agent_openai.principal_id == azurerm_user_assigned_identity.agent.principal_id && azurerm_user_assigned_identity.agent.principal_id == "aaaaaaaa-0000-0000-0000-000000000003"
    error_message = "Only the agent identity may hold the OpenAI role."
  }
  assert {
    condition     = length([for r in [azurerm_role_assignment.agent_openai, azurerm_role_assignment.pipeline_secrets, azurerm_role_assignment.agent_secrets] : r if r.role_definition_name == "Cognitive Services OpenAI User"]) == 1
    error_message = "Exactly one OpenAI role assignment expected."
  }
}

run "mcp_reads_no_secrets" {
  command = apply

  assert {
    condition = length([
      for r in [azurerm_role_assignment.pipeline_secrets, azurerm_role_assignment.agent_secrets, azurerm_role_assignment.agent_openai] :
      r if r.principal_id == azurerm_user_assigned_identity.mcp.principal_id
    ]) == 0
    error_message = "MCP identity must hold no role assignments."
  }
  assert {
    condition     = azurerm_role_assignment.pipeline_secrets.role_definition_name == "Key Vault Secrets User" && azurerm_role_assignment.agent_secrets.role_definition_name == "Key Vault Secrets User"
    error_message = "Pipeline and agent must hold Key Vault Secrets User."
  }
}

run "openai_capacity_is_capped" {
  command = plan

  variables {
    openai_capacity = 50
  }

  expect_failures = [var.openai_capacity]
}

run "environment_is_vnet_consumption_only" {
  command = apply

  assert {
    condition     = azurerm_container_app_environment.this.infrastructure_subnet_id == azurerm_subnet.aca.id
    error_message = "Environment must use snet-aca."
  }
  assert {
    condition     = azurerm_container_app_environment.this.internal_load_balancer_enabled == false
    error_message = "Environment must have a public load balancer."
  }
  assert {
    condition     = toset([for w in azurerm_container_app_environment.this.workload_profile : w.workload_profile_type]) == toset(["Consumption"])
    error_message = "Only Consumption workload profiles allowed."
  }
}
