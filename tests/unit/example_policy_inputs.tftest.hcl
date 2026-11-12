mock_provider "azapi" {
  alias = "mock"

  mock_resource "azapi_resource" {
    defaults = {
      id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.HybridContainerService/provisionedClusterInstances/test"
      tags = {}
    }
  }

  mock_data "azapi_resource" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ExtendedLocation/customLocations/mock"
    }
  }

  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

mock_provider "azurerm" {
  alias = "mock"

  mock_data "azurerm_client_config" {
    defaults = {
      tenant_id = "00000000-0000-0000-0000-000000000001"
    }
  }
}

mock_provider "terraform" {
  alias = "mock"
}

mock_provider "tls" {
  alias = "mock"
}

override_data {
  target = data.azapi_resource.logical_network

  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.AzureStackHCI/logicalNetworks/mock"
  }
}

# Planning avoids executing the example's readiness provisioner during this regression.
run "uses_direct_ids_without_live_lookups" {
  command = plan

  module {
    source = "./examples/default"
  }

  providers = {
    azapi     = azapi.mock
    azurerm   = azurerm.mock
    terraform = terraform.mock
    tls       = tls.mock
  }

  variables {
    aks_arc_name        = "policy-only-cluster"
    resource_group_name = "policy-only-rg"
    subscription_id     = "00000000-0000-0000-0000-000000000000"
    custom_location_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/policy-only-rg/providers/Microsoft.ExtendedLocation/customLocations/policy-only"
    logical_network_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/policy-only-rg/providers/Microsoft.AzureStackHCI/logicalNetworks/policy-only"
    keyvault_name       = "must-not-be-read"
    ssh_public_key      = "ssh-rsa mocked-policy-key"
    enable_telemetry    = false
  }

  assert {
    condition = (
      length(data.azapi_resource.customlocation) == 0 &&
      length(data.azapi_resource.logical_network) == 0 &&
      length(data.azurerm_key_vault.deployment_key_vault) == 0 &&
      local.effective_custom_location_id == var.custom_location_id &&
      local.effective_logical_network_id == var.logical_network_id &&
      module.test.rsa_private_key == ""
    )
    error_message = "Direct IDs must bypass HCI and Key Vault lookups while planning the real module."
  }
}

run "keeps_name_based_lookup_path" {
  command = plan

  module {
    source = "./examples/default"
  }

  providers = {
    azapi     = azapi.mock
    azurerm   = azurerm.mock
    terraform = terraform.mock
    tls       = tls.mock
  }

  variables {
    aks_arc_name         = "name-based-cluster"
    resource_group_name  = "test"
    subscription_id      = "00000000-0000-0000-0000-000000000000"
    custom_location_name = "custom-location"
    logical_network_name = "logical-network"
    keyvault_name        = "must-not-be-read"
    ssh_public_key       = "ssh-rsa mocked-policy-key"
    enable_telemetry     = false
  }

  assert {
    condition = (
      length(data.azapi_resource.customlocation) == 1 &&
      length(data.azapi_resource.logical_network) == 1 &&
      length(data.azurerm_key_vault.deployment_key_vault) == 0 &&
      local.effective_custom_location_id == data.azapi_resource.customlocation["lookup"].id &&
      local.effective_logical_network_id == data.azapi_resource.logical_network["lookup"].id &&
      module.test.rsa_private_key == ""
    )
    error_message = "Name-based inputs must retain their lookups and plan the actual module."
  }
}
