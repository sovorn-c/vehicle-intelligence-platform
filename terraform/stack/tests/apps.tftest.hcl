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
      default_domain = "happy-sky-123.australiaeast.azurecontainerapps.io"
    }
  }
}

mock_provider "random" {}

override_resource {
  target = azurerm_subnet.aca
  values = {
    id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-demo/providers/Microsoft.Network/virtualNetworks/vnet-vip-demo/subnets/snet-aca"
  }
}

override_resource {
  target = azurerm_subnet.pg
  values = {
    id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-demo/providers/Microsoft.Network/virtualNetworks/vnet-vip-demo/subnets/snet-pg"
  }
}

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
run "every_app_scales_to_zero_and_caps_at_one" {
  command = apply

  assert {
    condition = alltrue([
      for a in [azurerm_container_app.pipeline, azurerm_container_app.mcp, azurerm_container_app.agent] :
      a.template[0].min_replicas == 0 && a.template[0].max_replicas == 1
    ])
    error_message = "Every app must scale 0..1."
  }
  assert {
    condition = alltrue([
      for a in [azurerm_container_app.pipeline, azurerm_container_app.mcp, azurerm_container_app.agent] :
      a.revision_mode == "Single" && a.workload_profile_name == "Consumption"
    ])
    error_message = "Apps must use Single revision mode and the Consumption profile."
  }
}

run "pipeline_is_internal_only" {
  command = apply

  assert {
    condition     = azurerm_container_app.pipeline.ingress[0].external_enabled == false && azurerm_container_app.pipeline.ingress[0].target_port == 8000
    error_message = "Pipeline must be internal on 8000."
  }
}

run "mcp_host_allowlist_matches_fqdn" {
  command = apply

  assert {
    condition     = one([for e in azurerm_container_app.mcp.template[0].container[0].env : e.value if e.name == "VEHICLE_MCP_ALLOWED_HOSTS"]) == "ca-mcp.happy-sky-123.australiaeast.azurecontainerapps.io,ca-mcp"
    error_message = "MCP allowed hosts must match the FQDN."
  }
  assert {
    condition     = output.mcp_url == "https://ca-mcp.happy-sky-123.australiaeast.azurecontainerapps.io/mcp"
    error_message = "mcp_url mismatch."
  }
  assert {
    condition     = azurerm_container_app.mcp.ingress[0].external_enabled == true && azurerm_container_app.mcp.ingress[0].target_port == 8080
    error_message = "MCP must be external on 8080."
  }
}

run "mcp_has_no_secret_wiring" {
  command = apply

  assert {
    condition     = length(azurerm_container_app.mcp.secret) == 0
    error_message = "ca-mcp must have no secret blocks."
  }
  assert {
    condition     = length([for e in azurerm_container_app.mcp.template[0].container[0].env : e if e.secret_name != null && e.secret_name != ""]) == 0
    error_message = "ca-mcp env must not reference secrets."
  }
  assert {
    condition     = azurerm_container_app.mcp.identity[0].identity_ids == toset([azurerm_user_assigned_identity.mcp.id])
    error_message = "ca-mcp must use only the MCP identity."
  }
}

run "agent_runs_in_production_with_vault_secrets" {
  command = apply

  assert {
    condition = alltrue([
      one([for e in azurerm_container_app.agent.template[0].container[0].env : e.value if e.name == "ENVIRONMENT"]) == "production",
      one([for e in azurerm_container_app.agent.template[0].container[0].env : e.value if e.name == "DRAFTING_MODE"]) == "azure_openai",
      one([for e in azurerm_container_app.agent.template[0].container[0].env : e.value if e.name == "ENABLE_LIVE_DRAFTING"]) == "true",
      endswith(one([for e in azurerm_container_app.agent.template[0].container[0].env : e.value if e.name == "MCP_SERVER_URL"]), "/mcp"),
    ])
    error_message = "Agent must run in production with live Azure OpenAI drafting."
  }
  assert {
    condition = length(azurerm_container_app.agent.secret) == 6 && alltrue([
      for s in azurerm_container_app.agent.secret :
      s.key_vault_secret_id != null && s.key_vault_secret_id != "" && (s.value == null || s.value == "")
    ])
    error_message = "Every agent secret must come from Key Vault with no literal value."
  }
}

run "agent_jobs_share_agent_env" {
  command = apply

  assert {
    condition     = toset([for e in azurerm_container_app_job.agent_postdeploy_eval.template[0].container[0].env : e.name]) == toset([for e in azurerm_container_app.agent.template[0].container[0].env : e.name])
    error_message = "Eval job env must match ca-agent."
  }
  assert {
    condition     = toset([for e in azurerm_container_app_job.agent_seed.template[0].container[0].env : e.name]) == toset([for e in azurerm_container_app.agent.template[0].container[0].env : e.name])
    error_message = "Seed job env must match ca-agent."
  }
  assert {
    condition     = toset(values(output.job_names)) == toset(["job-pipeline-migrate", "job-pipeline-seed", "job-agent-seed", "job-agent-postdeploy-eval"])
    error_message = "Job names mismatch."
  }
}

run "tag_only_image_is_rejected" {
  command = plan

  variables {
    mcp_image = "ghcr.io/sovorn-c/vehicle-mcp-server:0.4.0"
  }

  expect_failures = [var.mcp_image]
}

run "latest_image_is_rejected" {
  command = plan

  variables {
    pipeline_image = "ghcr.io/sovorn-c/vehicle-intelligence-platform/pipeline:latest"
  }

  expect_failures = [var.pipeline_image]
}

run "deployed_images_keys_match_variables" {
  command = apply

  assert {
    condition     = keys(output.deployed_images) == ["agent_image", "mcp_image", "pipeline_image"]
    error_message = "deployed_images keys must equal the image variable names."
  }
}
