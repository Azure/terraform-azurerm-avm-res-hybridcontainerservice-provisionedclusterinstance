terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "0000000-0000-00000-000000"
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
  name      = var.custom_location_name
  parent_id = data.azurerm_resource_group.rg.id
  type      = "Microsoft.ExtendedLocation/customLocations@2021-08-15"
}

data "azapi_resource" "logical_network" {
  name      = var.logical_network_name
  parent_id = data.azurerm_resource_group.rg.id
  type      = "Microsoft.AzureStackHCI/logicalNetworks@2023-09-01-preview"
}

data "azurerm_key_vault" "deployment_key_vault" {
  name                = var.keyvault_name
  resource_group_name = var.resource_group_name
}

# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"

  agent_pool_profiles         = var.agent_pool_profiles
  custom_location_id          = data.azapi_resource.customlocation.id
  location                    = data.azurerm_resource_group.rg.location
  logical_network_id          = data.azapi_resource.logical_network.id
  name                        = var.aks_arc_name
  resource_group_id           = data.azurerm_resource_group.rg.id
  additional_nodepools        = var.additional_nodepools
  control_plane_count         = var.control_plane_count
  control_plane_ip            = var.control_plane_ip
  enable_telemetry            = var.enable_telemetry # see variables.tf
  rbac_admin_group_object_ids = var.rbac_admin_group_object_ids
  ssh_key_vault_id            = data.azurerm_key_vault.deployment_key_vault.id
}
