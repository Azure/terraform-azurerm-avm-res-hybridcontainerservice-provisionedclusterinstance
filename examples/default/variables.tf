variable "aks_arc_name" {
  type        = string
  default = "test"
  description = "The name of the hybrid aks"
}

variable "custom_location_name" {
  type        = string
  default="hxiacgh1-customlocation"
  description = "The name of the custom location."
}

variable "keyvault_name" {
  type        = string
  default = "hxiacgh1-kv-44"
  description = "The name of the key vault."
}

variable "logical_network_name" {
  type        = string
  default = "hxiacgh1-logicalnetwork"
  description = "The name of the logical network"
}

variable "resource_group_name" {
  type        = string
  default = "hxiacgh1-rg"
  description = "The resource group where the resources will be deployed."
}

variable "additional_nodepools" {
  type = map(object({
    count             = number
    enableAutoScaling = optional(bool, false)
    nodeTaints        = optional(list(string))
    nodeLabels        = optional(map(string))
    maxPods           = optional(number)
    osSKU             = optional(string, "CBLMariner")
    osType            = optional(string, "Linux")
    vmSize            = optional(string)
  }))
  default = {
    "pool1" = {
      count               = 1
      enable_auto_scaling = false
      os_sku              = "CBLMariner"
      os_type             = "Linux"
    }
  }
  description = "Map of agent pool configurations"
}

variable "agent_pool_profiles" {
  type = list(object({
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
  default = [{
    count             = 1
    enableAutoScaling = false
  }]
  description = "The agent pool profiles for the Kubernetes cluster."
}

variable "control_plane_count" {
  type        = number
  default     = 1
  description = "The count of the control plane"
}

variable "control_plane_ip" {
  type        = string
  default     = "192.168.1.191"
  description = "The IP address of the control plane"
}

variable "create_additional_nodepool" {
  type        = bool
  default     = true
  description = "Whether to create additional agent pool"
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "rbac_admin_group_object_ids" {
  type        = list(string)
  default     = ["ed888f99-66c1-48fe-992f-030f49ba50ed"]
  description = "The object IDs of the Azure AD groups that will be granted admin access to the Kubernetes cluster."
}
