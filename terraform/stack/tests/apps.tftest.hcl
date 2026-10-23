variables {
  pipeline_image = "ghcr.io/sovorn-c/vehicle-intelligence-platform/pipeline@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  mcp_image      = "ghcr.io/sovorn-c/vehicle-mcp-server@sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
  agent_image    = "ghcr.io/sovorn-c/vehicle-risk-agent@sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
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
override_resource {
  target = azurerm_key_vault_secret.pg_admin_password
  values = {
    versionless_id = "https://kv-vip-abcde.vault.azure.net/secrets/pg-admin-password"
  }
}

override_resource {
  target = azurerm_key_vault_secret.pipeline_database_url
  values = {
    versionless_id = "https://kv-vip-abcde.vault.azure.net/secrets/pipeline-database-url"
  }
}

override_resource {
  target = azurerm_key_vault_secret.agent_database_url
  values = {
    versionless_id = "https://kv-vip-abcde.vault.azure.net/secrets/agent-database-url"
  }
}

override_resource {
  target = azurerm_key_vault_secret.agent_requester_token
  values = {
    versionless_id = "https://kv-vip-abcde.vault.azure.net/secrets/agent-requester-token"
  }
}

override_resource {
  target = azurerm_key_vault_secret.agent_reviewer_token
  values = {
    versionless_id = "https://kv-vip-abcde.vault.azure.net/secrets/agent-reviewer-token"
  }
}

override_resource {
  target = azurerm_key_vault_secret.agent_operator_token
  values = {
    versionless_id = "https://kv-vip-abcde.vault.azure.net/secrets/agent-operator-token"
  }
}

override_resource {
  target = azurerm_key_vault_secret.agent_maintainer_token
  values = {
    versionless_id = "https://kv-vip-abcde.vault.azure.net/secrets/agent-maintainer-token"
  }
}

override_resource {
  target = azurerm_key_vault_secret.agent_snapshot_integrity_secret
  values = {
    versionless_id = "https://kv-vip-abcde.vault.azure.net/secrets/agent-snapshot-integrity-secret"
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

run "secret_wiring_is_pinned" {
  command = apply

  assert {
    condition = alltrue([
      for k, v in {
        DATABASE_URL = "pipeline-database-url"
      } :
      one([for e in azurerm_container_app.pipeline.template[0].container[0].env : e.secret_name if e.name == k]) == v &&
      one([for s in azurerm_container_app.pipeline.secret : s.key_vault_secret_id if s.name == v]) == "https://kv-vip-abcde.vault.azure.net/secrets/${v}"
    ])
    error_message = "pipeline: env must resolve to the intended Key Vault secrets."
  }
  assert {
    condition     = length(azurerm_container_app.pipeline.secret) == 1 && alltrue([for s in azurerm_container_app.pipeline.secret : s.identity == azurerm_user_assigned_identity.pipeline.id])
    error_message = "pipeline: every secret must be fetched with the pipeline identity."
  }
  assert {
    condition     = azurerm_container_app.pipeline.identity[0].identity_ids == toset([azurerm_user_assigned_identity.pipeline.id])
    error_message = "pipeline: must run as the pipeline identity only."
  }

  assert {
    condition = alltrue([
      for k, v in {
        DATABASE_URL              = "agent-database-url"
        REQUESTER_TOKEN           = "agent-requester-token"
        REVIEWER_TOKEN            = "agent-reviewer-token"
        OPERATOR_TOKEN            = "agent-operator-token"
        MAINTAINER_TOKEN          = "agent-maintainer-token"
        SNAPSHOT_INTEGRITY_SECRET = "agent-snapshot-integrity-secret"
      } :
      one([for e in azurerm_container_app.agent.template[0].container[0].env : e.secret_name if e.name == k]) == v &&
      one([for s in azurerm_container_app.agent.secret : s.key_vault_secret_id if s.name == v]) == "https://kv-vip-abcde.vault.azure.net/secrets/${v}"
    ])
    error_message = "agent: env must resolve to the intended Key Vault secrets."
  }
  assert {
    condition     = length(azurerm_container_app.agent.secret) == 6 && alltrue([for s in azurerm_container_app.agent.secret : s.identity == azurerm_user_assigned_identity.agent.id])
    error_message = "agent: every secret must be fetched with the agent identity."
  }
  assert {
    condition     = azurerm_container_app.agent.identity[0].identity_ids == toset([azurerm_user_assigned_identity.agent.id])
    error_message = "agent: must run as the agent identity only."
  }

  assert {
    condition = alltrue([
      for k, v in {
        DATABASE_URL = "pipeline-database-url"
      } :
      one([for e in azurerm_container_app_job.pipeline_migrate.template[0].container[0].env : e.secret_name if e.name == k]) == v &&
      one([for s in azurerm_container_app_job.pipeline_migrate.secret : s.key_vault_secret_id if s.name == v]) == "https://kv-vip-abcde.vault.azure.net/secrets/${v}"
    ])
    error_message = "pipeline_migrate: env must resolve to the intended Key Vault secrets."
  }
  assert {
    condition     = length(azurerm_container_app_job.pipeline_migrate.secret) == 1 && alltrue([for s in azurerm_container_app_job.pipeline_migrate.secret : s.identity == azurerm_user_assigned_identity.pipeline.id])
    error_message = "pipeline_migrate: every secret must be fetched with the pipeline identity."
  }
  assert {
    condition     = azurerm_container_app_job.pipeline_migrate.identity[0].identity_ids == toset([azurerm_user_assigned_identity.pipeline.id])
    error_message = "pipeline_migrate: must run as the pipeline identity only."
  }

  assert {
    condition = alltrue([
      for k, v in {
        DATABASE_URL = "pipeline-database-url"
      } :
      one([for e in azurerm_container_app_job.pipeline_seed.template[0].container[0].env : e.secret_name if e.name == k]) == v &&
      one([for s in azurerm_container_app_job.pipeline_seed.secret : s.key_vault_secret_id if s.name == v]) == "https://kv-vip-abcde.vault.azure.net/secrets/${v}"
    ])
    error_message = "pipeline_seed: env must resolve to the intended Key Vault secrets."
  }
  assert {
    condition     = length(azurerm_container_app_job.pipeline_seed.secret) == 1 && alltrue([for s in azurerm_container_app_job.pipeline_seed.secret : s.identity == azurerm_user_assigned_identity.pipeline.id])
    error_message = "pipeline_seed: every secret must be fetched with the pipeline identity."
  }
  assert {
    condition     = azurerm_container_app_job.pipeline_seed.identity[0].identity_ids == toset([azurerm_user_assigned_identity.pipeline.id])
    error_message = "pipeline_seed: must run as the pipeline identity only."
  }

  assert {
    condition = alltrue([
      for k, v in {
        DATABASE_URL              = "agent-database-url"
        REQUESTER_TOKEN           = "agent-requester-token"
        REVIEWER_TOKEN            = "agent-reviewer-token"
        OPERATOR_TOKEN            = "agent-operator-token"
        MAINTAINER_TOKEN          = "agent-maintainer-token"
        SNAPSHOT_INTEGRITY_SECRET = "agent-snapshot-integrity-secret"
      } :
      one([for e in azurerm_container_app_job.agent_seed.template[0].container[0].env : e.secret_name if e.name == k]) == v &&
      one([for s in azurerm_container_app_job.agent_seed.secret : s.key_vault_secret_id if s.name == v]) == "https://kv-vip-abcde.vault.azure.net/secrets/${v}"
    ])
    error_message = "agent_seed: env must resolve to the intended Key Vault secrets."
  }
  assert {
    condition     = length(azurerm_container_app_job.agent_seed.secret) == 6 && alltrue([for s in azurerm_container_app_job.agent_seed.secret : s.identity == azurerm_user_assigned_identity.agent.id])
    error_message = "agent_seed: every secret must be fetched with the agent identity."
  }
  assert {
    condition     = azurerm_container_app_job.agent_seed.identity[0].identity_ids == toset([azurerm_user_assigned_identity.agent.id])
    error_message = "agent_seed: must run as the agent identity only."
  }

  assert {
    condition = alltrue([
      for k, v in {
        DATABASE_URL              = "agent-database-url"
        REQUESTER_TOKEN           = "agent-requester-token"
        REVIEWER_TOKEN            = "agent-reviewer-token"
        OPERATOR_TOKEN            = "agent-operator-token"
        MAINTAINER_TOKEN          = "agent-maintainer-token"
        SNAPSHOT_INTEGRITY_SECRET = "agent-snapshot-integrity-secret"
      } :
      one([for e in azurerm_container_app_job.agent_postdeploy_eval.template[0].container[0].env : e.secret_name if e.name == k]) == v &&
      one([for s in azurerm_container_app_job.agent_postdeploy_eval.secret : s.key_vault_secret_id if s.name == v]) == "https://kv-vip-abcde.vault.azure.net/secrets/${v}"
    ])
    error_message = "agent_postdeploy_eval: env must resolve to the intended Key Vault secrets."
  }
  assert {
    condition     = length(azurerm_container_app_job.agent_postdeploy_eval.secret) == 6 && alltrue([for s in azurerm_container_app_job.agent_postdeploy_eval.secret : s.identity == azurerm_user_assigned_identity.agent.id])
    error_message = "agent_postdeploy_eval: every secret must be fetched with the agent identity."
  }
  assert {
    condition     = azurerm_container_app_job.agent_postdeploy_eval.identity[0].identity_ids == toset([azurerm_user_assigned_identity.agent.id])
    error_message = "agent_postdeploy_eval: must run as the agent identity only."
  }
}

run "agent_jobs_share_agent_env" {
  command = apply

  assert {
    condition     = toset([for e in azurerm_container_app_job.agent_seed.template[0].container[0].env : "${e.name}|${e.value == null ? "" : e.value}|${e.secret_name == null ? "" : e.secret_name}"]) == toset([for e in azurerm_container_app.agent.template[0].container[0].env : "${e.name}|${e.value == null ? "" : e.value}|${e.secret_name == null ? "" : e.secret_name}"])
    error_message = "agent_seed env (name, value, secret) must match ca-agent."
  }
  assert {
    condition     = toset([for e in azurerm_container_app_job.agent_postdeploy_eval.template[0].container[0].env : "${e.name}|${e.value == null ? "" : e.value}|${e.secret_name == null ? "" : e.secret_name}"]) == toset([for e in azurerm_container_app.agent.template[0].container[0].env : "${e.name}|${e.value == null ? "" : e.value}|${e.secret_name == null ? "" : e.secret_name}"])
    error_message = "agent_postdeploy_eval env (name, value, secret) must match ca-agent."
  }
}

run "jobs_are_single_shot_manual" {
  command = apply

  assert {
    condition = alltrue([
      for j in [azurerm_container_app_job.pipeline_migrate, azurerm_container_app_job.pipeline_seed, azurerm_container_app_job.agent_seed, azurerm_container_app_job.agent_postdeploy_eval] :
      j.manual_trigger_config[0].parallelism == 1 && j.manual_trigger_config[0].replica_completion_count == 1 && j.replica_timeout_in_seconds == 1800 && j.replica_retry_limit == 0
    ])
    error_message = "Jobs must be manual, single replica, 1800s timeout, no retries."
  }
  assert {
    condition     = azurerm_container_app_job.pipeline_migrate.template[0].container[0].command == tolist(["alembic", "upgrade", "head"])
    error_message = "migrate command mismatch."
  }
  assert {
    condition     = azurerm_container_app_job.pipeline_seed.template[0].container[0].command == tolist(["python", "-m", "nz_vehicle_data_pipeline.cli.seed", "--manifest", "fixtures/manifest.json", "--phase2"])
    error_message = "pipeline seed command mismatch."
  }
  assert {
    condition     = azurerm_container_app_job.agent_seed.template[0].container[0].command == tolist(["python", "-m", "vehicle_risk_agent.cli.seed"])
    error_message = "agent seed command mismatch."
  }
  assert {
    condition     = azurerm_container_app_job.agent_postdeploy_eval.template[0].container[0].command == tolist(["python", "-m", "vehicle_risk_agent.cli.postdeploy_eval"])
    error_message = "eval command mismatch."
  }
  assert {
    condition     = output.job_names.pipeline_migrate == "job-pipeline-migrate" && output.job_names.pipeline_seed == "job-pipeline-seed" && output.job_names.agent_seed == "job-agent-seed" && output.job_names.agent_postdeploy_eval == "job-agent-postdeploy-eval"
    error_message = "job_names mismatch."
  }
  assert {
    condition     = output.agent_url == "https://ca-agent.happy-sky-123.australiaeast.azurecontainerapps.io" && output.resource_group_name == "rg-vip-demo"
    error_message = "agent_url / resource_group_name mismatch."
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

run "agent_image_tag_is_rejected" {
  command = plan

  variables {
    agent_image = "ghcr.io/sovorn-c/vehicle-risk-agent:latest"
  }

  expect_failures = [var.agent_image]
}

run "deployed_images_keys_match_variables" {
  command = apply

  assert {
    condition     = keys(output.deployed_images) == ["agent_image", "mcp_image", "pipeline_image"]
    error_message = "deployed_images keys must equal the image variable names."
  }
}

run "each_workload_uses_its_own_image" {
  command = apply

  assert {
    condition     = azurerm_container_app.pipeline.template[0].container[0].image == var.pipeline_image
    error_message = "pipeline app must run pipeline_image."
  }

  assert {
    condition     = azurerm_container_app.mcp.template[0].container[0].image == var.mcp_image
    error_message = "mcp app must run mcp_image."
  }

  assert {
    condition     = azurerm_container_app.agent.template[0].container[0].image == var.agent_image
    error_message = "agent app must run agent_image."
  }

  assert {
    condition     = azurerm_container_app_job.pipeline_migrate.template[0].container[0].image == var.pipeline_image
    error_message = "pipeline migrate job must run pipeline_image."
  }

  assert {
    condition     = azurerm_container_app_job.pipeline_seed.template[0].container[0].image == var.pipeline_image
    error_message = "pipeline seed job must run pipeline_image."
  }

  assert {
    condition     = azurerm_container_app_job.agent_seed.template[0].container[0].image == var.agent_image
    error_message = "agent seed job must run agent_image."
  }

  assert {
    condition     = azurerm_container_app_job.agent_postdeploy_eval.template[0].container[0].image == var.agent_image
    error_message = "agent post-deploy eval job must run agent_image."
  }

  assert {
    condition     = output.deployed_images.pipeline_image == var.pipeline_image
    error_message = "deployed_images.pipeline_image must equal pipeline_image."
  }

  assert {
    condition     = output.deployed_images.mcp_image == var.mcp_image
    error_message = "deployed_images.mcp_image must equal mcp_image."
  }

  assert {
    condition     = output.deployed_images.agent_image == var.agent_image
    error_message = "deployed_images.agent_image must equal agent_image."
  }
}
