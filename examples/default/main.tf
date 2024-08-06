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
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "~> 0.1"
}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# This is required for resource modules
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azapi_resource" "customlocation" {
  type      = "Microsoft.ExtendedLocation/customLocations@2021-08-15"
  name      = var.customLocationName
  parent_id = data.azurerm_resource_group.rg.id
}

data "azapi_resource" "logicalNetwork" {
  type      = "Microsoft.AzureStackHCI/logicalNetworks@2023-09-01-preview"
  name      = var.logicalNetworkName
  parent_id = data.azurerm_resource_group.rg.id
}

data "azurerm_key_vault" "DeploymentKeyVault" {
  name                = var.keyvaultName
  resource_group_name = var.resource_group_name
}

data "azapi_resource" "arcbridge" {
  type      = "Microsoft.ResourceConnector/appliances@2022-10-27"
  name      = "${var.clusterName}-arcbridge"
  parent_id = data.azurerm_resource_group.rg.id
}


# This is the module call
# Do not specify location here due to the randomization above.
# Leaving location as `null` will cause the module to use the resource group location
# with a data source.
module "test" {
  source = "../../"
  # source             = "Azure/avm-<res/ptn>-<name>/azurerm"
  # ...
  location            = data.azurerm_resource_group.rg.location
  name                = var.aksArcName
  resource_group_name = data.azurerm_resource_group.rg.name

  enable_telemetry = var.enable_telemetry # see variables.tf

  customLocationId        = data.azapi_resource.customlocation.id
  logicalNetworkId        = data.azapi_resource.logicalNetwork.id
  agentPoolProfiles       = var.agentPoolProfiles
  sshKeyVaultId           = data.azurerm_key_vault.DeploymentKeyVault.id
  controlPlaneIp          = "192.168.1.190"
  arbId                   = data.azapi_resource.arcbridge.id
  kubernetesVersion       = "1.28.5"
  controlPlaneCount       = 1
  rbacAdminGroupObjectIds = ["ed888f99-66c1-48fe-992f-030f49ba50ed"]
}
