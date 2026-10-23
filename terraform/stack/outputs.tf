output "resource_group_name" {
  description = "Resource group holding the stack."
  value       = azurerm_resource_group.main.name
}

output "mcp_fqdn" {
  description = "Public FQDN of the MCP server."
  value       = local.mcp_fqdn
}

output "mcp_url" {
  description = "Public MCP endpoint URL."
  value       = "https://${local.mcp_fqdn}/mcp"
}

output "agent_url" {
  description = "Public risk agent URL."
  value       = "https://${azurerm_container_app.agent.ingress[0].fqdn}"
}

output "job_names" {
  description = "Container App Job names by role."
  value = {
    pipeline_migrate      = azurerm_container_app_job.pipeline_migrate.name
    pipeline_seed         = azurerm_container_app_job.pipeline_seed.name
    agent_seed            = azurerm_container_app_job.agent_seed.name
    agent_postdeploy_eval = azurerm_container_app_job.agent_postdeploy_eval.name
  }
}

output "deployed_images" {
  description = "Digest-pinned images deployed; keys equal the image variable names."
  value = {
    pipeline_image = var.pipeline_image
    mcp_image      = var.mcp_image
    agent_image    = var.agent_image
  }
}
