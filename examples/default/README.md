<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl
terraform {
  required_version = "~> 1.5"
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
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

## Resources

The following resources are used by this module:

- [azapi_resource.customlocation](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource) (data source)
- [azapi_resource.logical_network](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource) (data source)
- [azurerm_key_vault.deployment_key_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) (data source)
- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_aks_arc_name"></a> [aks\_arc\_name](#input\_aks\_arc\_name)

Description: The name of the hybrid aks

Type: `string`

### <a name="input_custom_location_name"></a> [custom\_location\_name](#input\_custom\_location\_name)

Description: The name of the custom location.

Type: `string`

### <a name="input_keyvault_name"></a> [keyvault\_name](#input\_keyvault\_name)

Description: The name of the key vault.

Type: `string`

### <a name="input_logical_network_name"></a> [logical\_network\_name](#input\_logical\_network\_name)

Description: The name of the logical network

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The resource group where the resources will be deployed.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_additional_nodepools"></a> [additional\_nodepools](#input\_additional\_nodepools)

Description: Map of agent pool configurations

Type:

```hcl
list(object({
    name              = string
    count             = number
    enableAutoScaling = optional(bool)
    nodeTaints        = optional(list(string))
    nodeLabels        = optional(map(string))
    maxPods           = optional(number)
    osSKU             = optional(string, "CBLMariner")
    osType            = optional(string, "Linux")
    vmSize            = optional(string)
    original          = optional(bool, false)
  }))
```

Default:

```json
[
  {
    "count": 1,
    "name": "pool1",
    "os_sku": "CBLMariner",
    "os_type": "Linux"
  }
]
```

### <a name="input_agent_pool_profiles"></a> [agent\_pool\_profiles](#input\_agent\_pool\_profiles)

Description: The agent pool profiles for the Kubernetes cluster.

Type:

```hcl
list(object({
    count             = number
    enableAutoScaling = optional(bool, false)
    nodeTaints        = optional(list(string))
    nodeLabels        = optional(map(string))
    maxPods           = optional(number)
    name              = optional(string)
    osSKU             = optional(string, "CBLMariner")
    osType            = optional(string, "Linux")
    vmSize            = optional(string)
  }))
```

Default:

```json
[
  {
    "count": 1,
    "enableAutoScaling": false,
    "maxPods": 30,
    "nodeLabels": {
      "nodepool": "default"
    },
    "nodeTaints": [
      "key1=value1:NoExecute"
    ]
  },
  {
    "count": 1,
    "enableAutoScaling": false,
    "maxPods": 30,
    "nodeLabels": {
      "nodepool": "default"
    },
    "nodeTaints": [
      "key2=value2:NoExecute"
    ]
  }
]
```

### <a name="input_control_plane_count"></a> [control\_plane\_count](#input\_control\_plane\_count)

Description: The count of the control plane

Type: `number`

Default: `1`

### <a name="input_control_plane_ip"></a> [control\_plane\_ip](#input\_control\_plane\_ip)

Description: The IP address of the control plane

Type: `string`

Default: `"192.168.1.190"`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_rbac_admin_group_object_ids"></a> [rbac\_admin\_group\_object\_ids](#input\_rbac\_admin\_group\_object\_ids)

Description: The object IDs of the Azure AD groups that will be granted admin access to the Kubernetes cluster.

Type: `list(string)`

Default:

```json
[
  "ed888f99-66c1-48fe-992f-030f49ba50ed"
]
```

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_test"></a> [test](#module\_test)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->