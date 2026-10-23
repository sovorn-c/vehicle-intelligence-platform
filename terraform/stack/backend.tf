# Remaining values (resource_group_name, storage_account_name, container_name,
# key) are supplied with -backend-config by the workflows.
terraform {
  backend "azurerm" {
    use_oidc         = true
    use_azuread_auth = true
  }
}
