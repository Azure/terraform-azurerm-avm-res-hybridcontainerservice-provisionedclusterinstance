variable "aks_arc_name" {
  type        = string
  description = "The name of the hybrid aks"
}

variable "custom_location_name" {
  type        = string
  description = "The name of the custom location."
}

variable "keyvault_name" {
  type        = string
  description = "The name of the key vault."
}

variable "logical_network_name" {
  type        = string
  description = "The name of the logical network"
}

variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
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

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}
