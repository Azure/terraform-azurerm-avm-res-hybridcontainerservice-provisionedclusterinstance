terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.12"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azapi_resource" "customlocation" {
  for_each = var.custom_location_id == null ? { lookup = var.custom_location_name } : {}

  name      = each.value
  parent_id = local.resource_group_id
  type      = "Microsoft.ExtendedLocation/customLocations@2021-08-15"
}

data "azapi_resource" "logical_network" {
  for_each = var.logical_network_id == null ? { lookup = var.logical_network_name } : {}

  name      = each.value
  parent_id = local.resource_group_id
  type      = "Microsoft.AzureStackHCI/logicalNetworks@2023-09-01-preview"
}

# Only used if ssh_public_key is not provided
data "azurerm_key_vault" "deployment_key_vault" {
  count = var.ssh_public_key == null && var.keyvault_name != null ? 1 : 0

  name                = var.keyvault_name
  resource_group_name = var.resource_group_name
}

# This is the module call
# Location is set via variable to match the custom location and logical network
module "test" {
  source = "../.."

  agent_pool_profiles         = var.agent_pool_profiles
  custom_location_id          = local.effective_custom_location_id
  location                    = var.location
  logical_network_id          = local.effective_logical_network_id
  name                        = var.aks_arc_name
  resource_group_id           = local.resource_group_id
  additional_nodepools        = var.additional_nodepools
  azure_hybrid_benefit        = var.azure_hybrid_benefit
  control_plane_count         = var.control_plane_count
  control_plane_ip            = var.control_plane_ip
  control_plane_vm_size       = var.control_plane_vm_size
  enable_azure_rbac           = var.enable_azure_rbac
  enable_telemetry            = var.enable_telemetry # see variables.tf
  kubernetes_version          = var.kubernetes_version
  nfs_csi_driver_enabled      = var.nfs_csi_driver_enabled
  rbac_admin_group_object_ids = var.rbac_admin_group_object_ids
  smb_csi_driver_enabled      = var.smb_csi_driver_enabled
  ssh_key_vault_id            = var.ssh_public_key == null && var.keyvault_name != null ? data.azurerm_key_vault.deployment_key_vault[0].id : null
  ssh_public_key              = var.ssh_public_key
}
