variable "additional_nodepools" {
  type = list(object({
    name              = string
    count             = number
    enableAutoScaling = optional(bool, false)
    nodeTaints        = optional(list(string))
    nodeLabels        = optional(map(string))
    maxPods           = optional(number)
    osSKU             = optional(string, "CBLMariner")
    osType            = optional(string, "Linux")
    vmSize            = optional(string)
  }))
  default = [
    {
      name    = "pool1"
      count   = 1
      os_sku  = "CBLMariner"
      os_type = "Linux"
    }
  ]
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
    nodeTaints = [
      "key1=value1:NoExecute"
    ]
    nodeLabels = {
      "nodepool" = "default"
    }
    maxPods = 30
    },
    # {
    #   count             = 1
    #   enableAutoScaling = false
    #   nodeTaints = [
    #     "key1=value1:NoExecute"
    #   ]
    #   nodeLabels = {
    #     "nodepool" = "default"
    #   }
    #   maxPods = 30
    # }
  ]
  description = "The agent pool profiles for the Kubernetes cluster."
}

variable "aks_arc_name" {
  type        = string
  default     = "test3"
  description = "The name of the hybrid aks"
}

variable "control_plane_count" {
  type        = number
  default     = 1
  description = "The count of the control plane"
}

variable "control_plane_ip" {
  type        = string
  default     = "192.168.1.193"
  description = "The IP address of the control plane"
}

variable "custom_location_name" {
  type        = string
  default     = "hxiacgh2-customlocation"
  description = "The name of the custom location."
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

variable "keyvault_name" {
  type        = string
  default     = "hxiacgh2-kv-97"
  description = "The name of the key vault."
}

variable "logical_network_name" {
  type        = string
  default     = "hxiacgh2-logicalnetwork"
  description = "The name of the logical network"
}

variable "rbac_admin_group_object_ids" {
  type        = list(string)
  default     = ["ed888f99-66c1-48fe-992f-030f49ba50ed"]
  description = "The object IDs of the Azure AD groups that will be granted admin access to the Kubernetes cluster."
}

variable "resource_group_name" {
  type        = string
  default     = "hxiacgh2-rg"
  description = "The resource group where the resources will be deployed."
}
