terraform {
  required_version = "~> 1.5"
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.13"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# This is required for resource modules
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azapi_resource" "customlocation" {
  type      = "Microsoft.ExtendedLocation/customLocations@2021-08-15"
  name      = var.custom_location_name
  parent_id = data.azurerm_resource_group.rg.id
}

data "azapi_resource" "logical_network" {
  type      = "Microsoft.AzureStackHCI/logicalNetworks@2023-09-01-preview"
  name      = var.logical_network_name
  parent_id = data.azurerm_resource_group.rg.id
}

data "azurerm_key_vault" "deployment_key_vault" {
  name                = var.keyvault_name
  resource_group_name = var.resource_group_name
}

# import {
#   id = "https://hxiacgh2-kv-97.vault.azure.net/secrets/AksArcAgentSshPrivateKeyPem1/305fe9226d2243cfb2d946546f365433"
#   to = module.test.azurerm_key_vault_secret.ssh_private_key_pem[0]
# }

# import {
#   id = "https://hxiacgh2-kv-97.vault.azure.net/secrets/AksArcAgentSshPublicKey1/2990442280674a829f2970129ad4ce34"
#   to = module.test.azurerm_key_vault_secret.ssh_public_key[0]
# }

# import {
#   id = "/subscriptions/de3c4d5e-af08-451a-a873-438d86ab6f4b/resourceGroups/hxiacgh2-rg/providers/Microsoft.Kubernetes/connectedClusters/test?api-version=2024-01-01"
#   to = module.test.azapi_resource.connected_cluster
# }

# import {
#   id = "/subscriptions/de3c4d5e-af08-451a-a873-438d86ab6f4b/resourceGroups/hxiacgh2-rg/providers/Microsoft.Kubernetes/connectedClusters/test/providers/Microsoft.HybridContainerService/provisionedClusterInstances/default?api-version=2024-01-01"
#   to = module.test.azapi_resource.provisioned_cluster_instance
# }

# import {
#   id = "/subscriptions/de3c4d5e-af08-451a-a873-438d86ab6f4b/resourceGroups/hxiacgh2-rg/providers/Microsoft.Kubernetes/connectedClusters/test/providers/Microsoft.HybridContainerService/provisionedClusterInstances/default/agentPools/pool1?api-version=2024-01-01"
#   to = module.test.azapi_resource.agent_pool[0]
# }

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"
  # source  = "Azure/avm-res-hybridcontainerservice-provisionedclusterinstance/azurerm"
  # version = "~> 0.1"

  location          = data.azurerm_resource_group.rg.location
  name              = var.aks_arc_name
  resource_group_id = data.azurerm_resource_group.rg.id

  enable_telemetry = var.enable_telemetry # see variables.tf

  custom_location_id          = data.azapi_resource.customlocation.id
  logical_network_id          = data.azapi_resource.logical_network.id
  agent_pool_profiles         = var.agent_pool_profiles
  ssh_key_vault_id            = data.azurerm_key_vault.deployment_key_vault.id
  control_plane_ip            = var.control_plane_ip
  control_plane_count         = var.control_plane_count
  rbac_admin_group_object_ids = var.rbac_admin_group_object_ids
  additional_nodepools        = var.additional_nodepools
}
