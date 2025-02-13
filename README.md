<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-res-hybridcontainerservice-provisionedclusterinstance

Module to onboard arc aks in azure stack hci.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

- <a name="requirement_modtm"></a> [modtm](#requirement\_modtm) (~> 0.3)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

- <a name="requirement_tls"></a> [tls](#requirement\_tls) (>= 3.1)

## Resources

The following resources are used by this module:

- [azapi_resource.agent_pool](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.connected_cluster](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource.provisioned_cluster_instance](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azurerm_key_vault_secret.ssh_private_key_pem](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_key_vault_secret.ssh_public_key](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_management_lock.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/management_lock) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [modtm_telemetry.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/resources/telemetry) (resource)
- [random_uuid.telemetry](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/uuid) (resource)
- [terraform_data.replacement](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)
- [terraform_data.wait_aks_vhd_ready](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) (resource)
- [tls_private_key.rsa_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [azurerm_client_config.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)
- [modtm_module_source.telemetry](https://registry.terraform.io/providers/azure/modtm/latest/docs/data-sources/module_source) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_agent_pool_profiles"></a> [agent\_pool\_profiles](#input\_agent\_pool\_profiles)

Description: The agent pool profiles

Type:

```hcl
list(object({
    count             = number
    enableAutoScaling = optional(bool)
    nodeTaints        = optional(list(string))
    nodeLabels        = optional(map(string))
    maxPods           = optional(number)
    name              = optional(string)
    osSKU             = optional(string, "CBLMariner")
    osType            = optional(string, "Linux")
    vmSize            = optional(string, "Standard_A4_v2")
  }))
```

### <a name="input_custom_location_id"></a> [custom\_location\_id](#input\_custom\_location\_id)

Description: The id of the Custom location that used to create hybrid aks

Type: `string`

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the resource should be deployed.

Type: `string`

### <a name="input_logical_network_id"></a> [logical\_network\_id](#input\_logical\_network\_id)

Description: The id of the logical network that the AKS nodes will be connected to.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the hybrid aks

Type: `string`

### <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id)

Description: The resource group id where the resources will be deployed.

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

Default: `[]`

### <a name="input_azure_hybrid_benefit"></a> [azure\_hybrid\_benefit](#input\_azure\_hybrid\_benefit)

Description: The Azure Hybrid Benefit for the kubernetes cluster.

Type: `string`

Default: `"False"`

### <a name="input_control_plane_count"></a> [control\_plane\_count](#input\_control\_plane\_count)

Description: The count of the control plane

Type: `number`

Default: `1`

### <a name="input_control_plane_ip"></a> [control\_plane\_ip](#input\_control\_plane\_ip)

Description: The ip address of the control plane

Type: `string`

Default: `null`

### <a name="input_control_plane_vm_size"></a> [control\_plane\_vm\_size](#input\_control\_plane\_vm\_size)

Description: The size of the control plane VM

Type: `string`

Default: `"Standard_A4_v2"`

### <a name="input_customer_managed_key"></a> [customer\_managed\_key](#input\_customer\_managed\_key)

Description: A map describing customer-managed keys to associate with the resource. This includes the following properties:
- `key_vault_resource_id` - The resource ID of the Key Vault where the key is stored.
- `key_name` - The name of the key.
- `key_version` - (Optional) The version of the key. If not specified, the latest version is used.
- `user_assigned_identity` - (Optional) An object representing a user-assigned identity with the following properties:
  - `resource_id` - The resource ID of the user-assigned identity.

Type:

```hcl
object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
```

Default: `null`

### <a name="input_enable_azure_rbac"></a> [enable\_azure\_rbac](#input\_enable\_azure\_rbac)

Description: Enable Azure RBAC for the kubernetes cluster

Type: `bool`

Default: `true`

### <a name="input_enable_oidc_issuer"></a> [enable\_oidc\_issuer](#input\_enable\_oidc\_issuer)

Description: (Optional) Enable OIDC Issuer

Type: `bool`

Default: `null`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_enable_workload_identity"></a> [enable\_workload\_identity](#input\_enable\_workload\_identity)

Description: (Optional) Enable Workload Identity

Type: `bool`

Default: `null`

### <a name="input_is_exported"></a> [is\_exported](#input\_is\_exported)

Description: Indicates whether the resource is exported

Type: `bool`

Default: `false`

### <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version)

Description: The kubernetes version

Type: `string`

Default: `""`

### <a name="input_lock"></a> [lock](#input\_lock)

Description: Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Type:

```hcl
object({
    kind = string
    name = optional(string, null)
  })
```

Default: `null`

### <a name="input_managed_identities"></a> [managed\_identities](#input\_managed\_identities)

Description: Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.

Type:

```hcl
object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
```

Default: `{}`

### <a name="input_nfs_csi_driver_enabled"></a> [nfs\_csi\_driver\_enabled](#input\_nfs\_csi\_driver\_enabled)

Description: Enable the NFS CSI driver for the kubernetes cluster.

Type: `bool`

Default: `true`

### <a name="input_pod_cidr"></a> [pod\_cidr](#input\_pod\_cidr)

Description: The CIDR range for the pods in the kubernetes cluster

Type: `string`

Default: `"10.244.0.0/16"`

### <a name="input_rbac_admin_group_object_ids"></a> [rbac\_admin\_group\_object\_ids](#input\_rbac\_admin\_group\_object\_ids)

Description: The object id of the admin group of the azure rbac

Type: `list(string)`

Default: `[]`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_smb_csi_driver_enabled"></a> [smb\_csi\_driver\_enabled](#input\_smb\_csi\_driver\_enabled)

Description: Enable the SMB CSI driver for the kubernetes cluster.

Type: `bool`

Default: `true`

### <a name="input_ssh_key_vault_id"></a> [ssh\_key\_vault\_id](#input\_ssh\_key\_vault\_id)

Description: The id of the key vault that contains the SSH public and private keys.

Type: `string`

Default: `null`

### <a name="input_ssh_private_key_pem_secret_name"></a> [ssh\_private\_key\_pem\_secret\_name](#input\_ssh\_private\_key\_pem\_secret\_name)

Description: The name of the secret in the key vault that contains the SSH private key PEM.

Type: `string`

Default: `"AksArcAgentSshPrivateKeyPem"`

### <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key)

Description: The SSH public key that will be used to access the kubernetes cluster nodes. If not specified, a new SSH key pair will be generated.

Type: `string`

Default: `null`

### <a name="input_ssh_public_key_secret_name"></a> [ssh\_public\_key\_secret\_name](#input\_ssh\_public\_key\_secret\_name)

Description: The name of the secret in the key vault that contains the SSH public key.

Type: `string`

Default: `"AksArcAgentSshPublicKey"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

Default: `null`

### <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id)

Description: (Optional) Value of the tenant id

Type: `string`

Default: `""`

## Outputs

The following outputs are exported:

### <a name="output_aks_cluster"></a> [aks\_cluster](#output\_aks\_cluster)

Description: AKS Arc Cluster instance

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: AKS Arc Provisioned Cluster instance

### <a name="output_rsa_private_key"></a> [rsa\_private\_key](#output\_rsa\_private\_key)

Description: The RSA private key

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->