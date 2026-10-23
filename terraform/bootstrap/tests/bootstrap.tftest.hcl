mock_provider "azurerm" {
  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id       = "11111111-1111-1111-1111-111111111111"
      object_id       = "22222222-2222-2222-2222-222222222222"
      subscription_id = "33333333-3333-3333-3333-333333333333"
    }
  }

  mock_data "azurerm_subscription" {
    defaults = {
      id = "/subscriptions/33333333-3333-3333-3333-333333333333"
    }
  }

  mock_resource "azurerm_resource_group" {
    defaults = {
      id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-tfstate"
    }
  }

  mock_resource "azurerm_storage_account" {
    defaults = {
      id = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-tfstate/providers/Microsoft.Storage/storageAccounts/stvipstate"
    }
  }

  mock_resource "azurerm_user_assigned_identity" {
    defaults = {
      id           = "/subscriptions/33333333-3333-3333-3333-333333333333/resourceGroups/rg-vip-tfstate/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-vip-deployer"
      principal_id = "44444444-4444-4444-4444-444444444444"
      client_id    = "55555555-5555-5555-5555-555555555555"
    }
  }
}

variables {
  budget_contact_email = "owner@example.com"
  budget_start_date    = "2026-11-01T00:00:00Z"
}

run "federated_subject_is_environment_scoped" {
  command = plan

  assert {
    condition     = azurerm_federated_identity_credential.github.subject == "repo:sovorn-c/vehicle-intelligence-platform:environment:azure"
    error_message = "federated subject must be scoped to the azure environment"
  }

  assert {
    condition     = azurerm_federated_identity_credential.github.issuer == "https://token.actions.githubusercontent.com"
    error_message = "issuer must be the GitHub Actions OIDC issuer"
  }

  assert {
    condition     = azurerm_federated_identity_credential.github.audience == tolist(["api://AzureADTokenExchange"])
    error_message = "audience must be api://AzureADTokenExchange"
  }
}

run "state_storage_rejects_shared_keys" {
  command = plan

  assert {
    condition     = azurerm_storage_account.tfstate.shared_access_key_enabled == false
    error_message = "shared access keys must be disabled"
  }

  assert {
    condition     = azurerm_storage_account.tfstate.min_tls_version == "TLS1_2"
    error_message = "minimum TLS must be 1.2"
  }

  assert {
    condition     = azurerm_storage_account.tfstate.allow_nested_items_to_be_public == false
    error_message = "public blob access must be disabled"
  }

  assert {
    condition     = azurerm_storage_account.tfstate.blob_properties[0].versioning_enabled == true
    error_message = "blob versioning must be on"
  }
}

run "budget_notifies_at_50_80_100" {
  command = plan

  assert {
    condition     = toset([for n in azurerm_consumption_budget_subscription.demo.notification : n.threshold]) == toset([50, 80, 100])
    error_message = "budget thresholds must be 50, 80 and 100"
  }

  assert {
    condition     = alltrue([for n in azurerm_consumption_budget_subscription.demo.notification : n.threshold_type == (n.threshold == 100 ? "Forecasted" : "Actual")])
    error_message = "100 must be Forecasted; 50 and 80 must be Actual"
  }

  assert {
    condition     = alltrue([for n in azurerm_consumption_budget_subscription.demo.notification : n.contact_emails == tolist(["owner@example.com"])])
    error_message = "every notification must go to budget_contact_email"
  }
}

run "rbac_admin_is_constrained" {
  command = plan

  assert {
    condition     = azurerm_role_assignment.deployer_rbac_admin.condition_version == "2.0"
    error_message = "ABAC condition_version must be 2.0"
  }

  assert {
    condition     = alltrue([for g in ["4633458b-17de-408a-b874-0445c86b69e6", "b86a8fe4-44ce-4948-aee5-eccb2c155cd7", "5e0bd9bd-7b93-4f28-af87-19fc36ad61bd"] : strcontains(azurerm_role_assignment.deployer_rbac_admin.condition, g)])
    error_message = "condition must list the three permitted role GUIDs"
  }

  assert {
    condition     = strcontains(azurerm_role_assignment.deployer_rbac_admin.condition, "roleAssignments/write") && strcontains(azurerm_role_assignment.deployer_rbac_admin.condition, "roleAssignments/delete")
    error_message = "condition must cover both write and delete"
  }
}

run "budget_over_credit_is_rejected" {
  command = plan

  variables {
    budget_amount = 500
  }

  expect_failures = [var.budget_amount]
}

run "budget_start_must_be_first_of_month" {
  command = plan

  variables {
    budget_start_date = "2026-11-15T00:00:00Z"
  }

  expect_failures = [var.budget_start_date]
}
