variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the hybrid aks"
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

# required AVM interfaces
# remove only if not supported by the resource
# tflint-ignore: terraform_unused_declarations
variable "customer_managed_key" {
  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default     = null
  description = <<DESCRIPTION
A map describing customer-managed keys to associate with the resource. This includes the following properties:
- `key_vault_resource_id` - The resource ID of the Key Vault where the key is stored.
- `key_name` - The name of the key.
- `key_version` - (Optional) The version of the key. If not specified, the latest version is used.
- `user_assigned_identity` - (Optional) An object representing a user-assigned identity with the following properties:
  - `resource_id` - The resource ID of the user-assigned identity.
DESCRIPTION  
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "The lock level must be one of: 'None', 'CanNotDelete', or 'ReadOnly'."
  }
}

# tflint-ignore: terraform_unused_declarations
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
DESCRIPTION
  nullable    = false
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - The description of the role assignment.
- `skip_service_principal_aad_check` - If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - The condition which will be used to scope the role assignment.
- `condition_version` - The version of the condition syntax. Valid values are '2.0'.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.
DESCRIPTION
  nullable    = false
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "custom_location_id" {
  description = "The id of the Custom location that used to create hybrid aks"
  type        = string
}

variable "logical_network_id" {
  description = "The id of the logical network that the AKS nodes will be connected to."
  type        = string
}

variable "control_plane_ip" {
  type        = string
  description = "The ip address of the control plane"
}

variable "ssh_public_key" {
  type        = string
  description = "The SSH public key that will be used to access the kubernetes cluster nodes. If not specified, a new SSH key pair will be generated."
  default     = null
}

variable "ssh_key_vault_id" {
  type        = string
  description = "The id of the key vault that contains the SSH public and private keys."
  default     = null
}

variable "ssh_public_key_secret_name" {
  type        = string
  description = "The name of the secret in the key vault that contains the SSH public key."
  default     = "AksArcAgentSshPublicKey"
}

variable "ssh_private_key_pem_secret_name" {
  type        = string
  description = "The name of the secret in the key vault that contains the SSH private key PEM."
  default     = "AksArcAgentSshPrivateKeyPem"
}

# putting validation here is because the condition of a variable can only refer to the variable itself in terraform.
locals {
  # tflint-ignore: terraform_unused_declarations
  validate_ssh_key_vault = (var.ssh_public_key == null && var.ssh_key_vault_id == null) ? tobool("sshPrivateKeyPemSecretName must be specified if sshPublicKey is not specified") : true
  validate_ssh_key       = (var.ssh_public_key == null && var.ssh_private_key_pem_secret_name == "") ? tobool("sshPrivateKeyPemSecretName must be specified if sshPublicKey is not specified") : true
  validate_rbac          = (var.enable_azure_rbac == true && length(var.rbac_admin_group_object_ids) == 0) ? tobool("At least one admin group object id must be specified") : true
}

variable "enable_azure_rbac" {
  type        = bool
  description = "Enable Azure RBAC for the kubernetes cluster"
  default     = true
}

variable "rbac_admin_group_object_ids" {
  type        = list(string)
  description = "The object id of the admin group of the azure rbac"
  default     = []
}

variable "kubernetes_version" {
  type        = string
  description = "The kubernetes version"
  default     = "1.28.5"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetesVersion must be in the format of 'x.y.z'"
  }
}

variable "control_plane_count" {
  type        = number
  description = "The count of the control plane"
  default     = 1
}

variable "control_plane_vm_size" {
  type        = string
  description = "The size of the control plane VM"
  default     = "Standard_A4_v2"
}

variable "pod_cidr" {
  type        = string
  description = "The CIDR range for the pods in the kubernetes cluster"
  default     = "10.244.0.0/16"
}

variable "agent_pool_profiles" {
  type = list(object({
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
  description = "The agent pool profiles"

  validation {
    condition     = length(var.agent_pool_profiles) > 0
    error_message = "At least one agent pool profile must be specified"
  }

  validation {
    condition = length([
      for profile in var.agent_pool_profiles : true
      if profile.enableAutoScaling == false || profile.enableAutoScaling == null
    ]) == length(var.agent_pool_profiles)
    error_message = "Agent pool profiles enableAutoScaling is not supported yet."
  }

  validation {
    condition = length([
      for profile in var.agent_pool_profiles : true
      if profile.osType == null
      || contains(["Linux", "Windows"], profile.osType)
    ]) == length(var.agent_pool_profiles)
    error_message = "Agent pool profiles osType must be either 'Linux' or 'Windows'"
  }

  validation {
    condition = length([
      for profile in var.agent_pool_profiles : true
      if profile.osSKU == null
      || contains(["CBLMariner", "Windows2019", "Windows2022"], profile.osSKU)
    ]) == length(var.agent_pool_profiles)
    error_message = "Agent pool profiles osSKU must be either 'CBLMariner', 'Windows2019' or 'Windows2022'"
  }

  validation {
    condition = length([
      for profile in var.agent_pool_profiles : true
      if profile.osType == null || profile.osSKU == null
      || !contains(["Linux"], profile.osType) || contains(["CBLMariner"], profile.osSKU)
    ]) == length(var.agent_pool_profiles)
    error_message = "Agent pool profiles osSKU must be 'CBLMariner' if osType is 'Linux'"
  }

  validation {
    condition = length([
      for profile in var.agent_pool_profiles : true
      if profile.osType == null || profile.osSKU == null
      || !contains(["Windows"], profile.osType) || contains(["Windows2019", "Windows2022"], profile.osSKU)
    ]) == length(var.agent_pool_profiles)
    error_message = "Agent pool profiles osSKU must be 'Windows2019' or 'Windows2022' if osType is 'Windows'"
  }
}

variable "is_exported" {
  description = "Indicates whether the resource is exported"
  type        = bool
  default     = false
}
