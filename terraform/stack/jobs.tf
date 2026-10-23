resource "azurerm_container_app_job" "pipeline_migrate" {
  name                         = "job-pipeline-migrate"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  workload_profile_name        = "Consumption"
  replica_timeout_in_seconds   = 1800
  replica_retry_limit          = 0

  depends_on = [azurerm_role_assignment.pipeline_secrets]

  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

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

  template {
    container {
      name    = "job-pipeline-migrate"
      image   = var.pipeline_image
      command = ["alembic", "upgrade", "head"]
      cpu     = 0.5
      memory  = "1Gi"

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

resource "azurerm_container_app_job" "pipeline_seed" {
  name                         = "job-pipeline-seed"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  workload_profile_name        = "Consumption"
  replica_timeout_in_seconds   = 1800
  replica_retry_limit          = 0

  depends_on = [azurerm_role_assignment.pipeline_secrets]

  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

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

  template {
    container {
      name    = "job-pipeline-seed"
      image   = var.pipeline_image
      command = ["python", "-m", "nz_vehicle_data_pipeline.cli.seed", "--manifest", "fixtures/manifest.json", "--phase2"]
      cpu     = 0.5
      memory  = "1Gi"

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

resource "azurerm_container_app_job" "agent_seed" {
  name                         = "job-agent-seed"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  workload_profile_name        = "Consumption"
  replica_timeout_in_seconds   = 1800
  replica_retry_limit          = 0

  depends_on = [azurerm_role_assignment.agent_secrets, azurerm_role_assignment.agent_openai]

  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

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

  template {
    container {
      name    = "job-agent-seed"
      image   = var.agent_image
      command = ["python", "-m", "vehicle_risk_agent.cli.seed"]
      cpu     = 0.5
      memory  = "1Gi"

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

resource "azurerm_container_app_job" "agent_postdeploy_eval" {
  name                         = "job-agent-postdeploy-eval"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.this.id
  workload_profile_name        = "Consumption"
  replica_timeout_in_seconds   = 1800
  replica_retry_limit          = 0

  depends_on = [azurerm_role_assignment.agent_secrets, azurerm_role_assignment.agent_openai]

  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

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

  template {
    container {
      name    = "job-agent-postdeploy-eval"
      image   = var.agent_image
      command = ["python", "-m", "vehicle_risk_agent.cli.postdeploy_eval"]
      cpu     = 0.5
      memory  = "1Gi"

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
