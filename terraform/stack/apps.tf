locals {
  app_names = {
    pipeline = "ca-pipeline"
    mcp      = "ca-mcp"
    agent    = "ca-agent"
  }

  # Computed from the environment domain, not the app, to avoid a self-reference.
  mcp_fqdn = "${local.app_names.mcp}.${azurerm_container_app_environment.this.default_domain}"

  pipeline_secret_names = ["pipeline-database-url"]

  agent_secret_names = [
    "agent-database-url",
    "agent-requester-token",
    "agent-reviewer-token",
    "agent-operator-token",
    "agent-maintainer-token",
    "agent-snapshot-integrity-secret",
  ]

  # Shared by ca-agent and both agent jobs so they cannot drift.
  agent_env = [
    { name = "ENVIRONMENT", value = "production", secret_name = null },
    # [UNVERIFIED] until Phase 4: in-environment name resolution via http://<app-name>.
    { name = "MCP_SERVER_URL", value = "http://${local.app_names.mcp}/mcp", secret_name = null },
    { name = "DRAFTING_MODE", value = "azure_openai", secret_name = null },
    { name = "ENABLE_LIVE_DRAFTING", value = "true", secret_name = null },
    { name = "AZURE_CLIENT_ID", value = azurerm_user_assigned_identity.agent.client_id, secret_name = null },
    { name = "AZURE_OPENAI_ENDPOINT", value = azurerm_cognitive_account.openai.endpoint, secret_name = null },
    { name = "AZURE_OPENAI_DEPLOYMENT", value = azurerm_cognitive_deployment.chat.name, secret_name = null },
    { name = "DATABASE_URL", value = null, secret_name = "agent-database-url" },
    { name = "REQUESTER_TOKEN", value = null, secret_name = "agent-requester-token" },
    { name = "REVIEWER_TOKEN", value = null, secret_name = "agent-reviewer-token" },
    { name = "OPERATOR_TOKEN", value = null, secret_name = "agent-operator-token" },
    { name = "MAINTAINER_TOKEN", value = null, secret_name = "agent-maintainer-token" },
    { name = "SNAPSHOT_INTEGRITY_SECRET", value = null, secret_name = "agent-snapshot-integrity-secret" },
  ]

  pipeline_env = [
    { name = "DATABASE_URL", value = null, secret_name = "pipeline-database-url" },
  ]
}

resource "azurerm_container_app" "pipeline" {
  name                         = local.app_names.pipeline
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.pipeline.id]
  }

  dynamic "secret" {
    for_each = local.pipeline_secret_names
    content {
      name                = secret.value
      key_vault_secret_id = local.secret_ids[secret.value]
      identity            = azurerm_user_assigned_identity.pipeline.id
    }
  }

  ingress {
    external_enabled = false
    target_port      = 8000

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = local.app_names.pipeline
      image  = var.pipeline_image
      cpu    = 0.5
      memory = "1Gi"

      dynamic "env" {
        for_each = local.pipeline_env
        content {
          name        = env.value.name
          value       = env.value.value
          secret_name = env.value.secret_name
        }
      }
    }
  }
}

resource "azurerm_container_app" "mcp" {
  name                         = local.app_names.mcp
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  # No secret blocks: MCP reads no secrets.
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mcp.id]
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = local.app_names.mcp
      image  = var.mcp_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "VEHICLE_MCP_TRANSPORT"
        value = "http"
      }
      env {
        name  = "VEHICLE_MCP_HTTP_HOST"
        value = "0.0.0.0"
      }
      env {
        name  = "VEHICLE_MCP_HTTP_PORT"
        value = "8080"
      }
      env {
        name  = "VEHICLE_MCP_ALLOW_INSECURE_BIND"
        value = "true"
      }
      env {
        # [UNVERIFIED] until Phase 4: in-environment name resolution via http://<app-name>.
        name  = "VEHICLE_MCP_PIPELINE_BASE_URL"
        value = "http://${local.app_names.pipeline}"
      }
      env {
        name  = "VEHICLE_MCP_ALLOWED_HOSTS"
        value = "${local.mcp_fqdn},${local.app_names.mcp}"
      }
      env {
        name  = "VEHICLE_MCP_ALLOWED_ORIGINS"
        value = "https://${local.mcp_fqdn}"
      }
    }
  }
}

resource "azurerm_container_app" "agent" {
  name                         = local.app_names.agent
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.agent.id]
  }

  dynamic "secret" {
    for_each = local.agent_secret_names
    content {
      name                = secret.value
      key_vault_secret_id = local.secret_ids[secret.value]
      identity            = azurerm_user_assigned_identity.agent.id
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8001

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = local.app_names.agent
      image  = var.agent_image
      cpu    = 0.5
      memory = "1Gi"

      dynamic "env" {
        for_each = local.agent_env
        content {
          name        = env.value.name
          value       = env.value.value
          secret_name = env.value.secret_name
        }
      }
    }
  }
}
