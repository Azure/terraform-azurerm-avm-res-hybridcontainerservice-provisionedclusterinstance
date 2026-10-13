mock_provider "azapi" {
  alias = "mock"

  mock_resource "azapi_resource" {
    defaults = {
      tags = {}
    }
  }
}

mock_provider "azurerm" {
  alias = "mock"
}

mock_provider "modtm" {
  alias = "mock"
}

mock_provider "random" {
  alias = "mock"
}

mock_provider "tls" {
  alias = "mock"
}

override_resource {
  target = azapi_resource.connected_cluster
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Kubernetes/connectedClusters/test"
  }
}

override_resource {
  target = azapi_resource.provisioned_cluster_instance
  values = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Kubernetes/connectedClusters/test/providers/Microsoft.HybridContainerService/provisionedClusterInstances/default"
  }
}

variables {
  name               = "test"
  location           = "westeurope"
  resource_group_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test"
  custom_location_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ExtendedLocation/customLocations/test"
  logical_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.AzureStackHCI/logicalNetworks/test"
  tenant_id          = "00000000-0000-0000-0000-000000000000"
  ssh_public_key     = "ssh-rsa mocked-test-key"
  enable_telemetry   = false
  is_exported        = true
  agent_pool_profiles = [{
    name  = "default"
    count = 1
  }]
  additional_nodepools = [{
    name   = "poolone"
    count  = 2
    vmSize = "Standard_A4_v2"
  }]
}

run "propagates_tags_without_changing_node_configuration" {
  command = apply

  providers = {
    azapi   = azapi.mock
    azurerm = azurerm.mock
    modtm   = modtm.mock
    random  = random.mock
    tls     = tls.mock
  }

  variables {
    tags = { environment = "unit-test" }
  }

  assert {
    condition     = azapi_resource.agent_pool[0].tags == var.tags && azapi_resource.connected_cluster.tags == var.tags
    error_message = "Connected cluster and additional agent pools must receive the supplied tags."
  }

  assert {
    condition     = azapi_resource.agent_pool[0].body.properties.count == 2 && azapi_resource.agent_pool[0].body.properties.vmSize == "Standard_A4_v2" && azapi_resource.agent_pool[0].body.extendedLocation.name == var.custom_location_id
    error_message = "Tag propagation must preserve node count, VM size, and custom location."
  }

  assert {
    condition     = azapi_resource.provisioned_cluster_instance.body.properties.cloudProviderProfile.infraNetworkProfile.vnetSubnetIds == [var.logical_network_id] && azapi_resource.provisioned_cluster_instance.body.properties.storageProfile.smbCsiDriver.enabled && azapi_resource.provisioned_cluster_instance.body.properties.storageProfile.nfsCsiDriver.enabled
    error_message = "Tag propagation must preserve logical network and storage-driver configuration."
  }

  assert {
    condition     = length(terraform_data.wait_aks_vhd_ready) == 0 && length(modtm_telemetry.telemetry) == 0 && length(tls_private_key.rsa_key) == 0
    error_message = "This mocked test must not invoke readiness, telemetry, or key generation."
  }
}

run "preserves_no_tags_when_omitted" {
  command   = apply
  state_key = "omitted_tags"

  providers = {
    azapi   = azapi.mock
    azurerm = azurerm.mock
    modtm   = modtm.mock
    random  = random.mock
    tls     = tls.mock
  }

  assert {
    condition     = var.tags == null && length(azapi_resource.agent_pool[0].tags) == 0
    error_message = "Omitted tags must not introduce any tags."
  }
}

run "preserves_empty_tags" {
  command   = apply
  state_key = "empty_tags"

  providers = {
    azapi   = azapi.mock
    azurerm = azurerm.mock
    modtm   = modtm.mock
    random  = random.mock
    tls     = tls.mock
  }

  variables {
    tags = {}
  }

  assert {
    condition     = length(azapi_resource.agent_pool[0].tags) == 0
    error_message = "An explicitly empty tags map must remain empty."
  }
}
