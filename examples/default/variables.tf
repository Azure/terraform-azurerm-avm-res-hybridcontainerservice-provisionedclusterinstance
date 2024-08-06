variable "aksArcName" {
  type        = string
  description = "The name of the hybrid aks"
}

variable "clusterName" {
  type        = string
  description = "The name of the HCI cluster. Must be the same as the name when preparing AD."

  validation {
    condition     = length(var.clusterName) < 16 && length(var.clusterName) > 0
    error_message = "value of clusterName should be less than 16 characters and greater than 0 characters"
  }
}

variable "customLocationName" {
  type        = string
  description = "The name of the custom location."
}

variable "keyvaultName" {
  type        = string
  description = "The name of the key vault."
}

variable "logicalNetworkName" {
  type        = string
  description = "The name of the logical network"
}

variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "agentPoolProfiles" {
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
