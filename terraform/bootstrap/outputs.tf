output "azure_client_id" {
  description = "GitHub environment variable AZURE_CLIENT_ID."
  value       = azurerm_user_assigned_identity.deployer.client_id
}

output "azure_tenant_id" {
  description = "GitHub environment variable AZURE_TENANT_ID."
  value       = data.azurerm_client_config.current.tenant_id
}

output "azure_subscription_id" {
  description = "GitHub environment variable AZURE_SUBSCRIPTION_ID."
  value       = data.azurerm_client_config.current.subscription_id
}

output "tfstate_resource_group" {
  description = "GitHub environment variable TFSTATE_RESOURCE_GROUP."
  value       = azurerm_resource_group.tfstate.name
}

output "tfstate_storage_account" {
  description = "GitHub environment variable TFSTATE_STORAGE_ACCOUNT."
  value       = azurerm_storage_account.tfstate.name
}
