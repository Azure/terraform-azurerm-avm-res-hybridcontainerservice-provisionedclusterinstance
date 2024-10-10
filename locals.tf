locals {
  agent_pool_profiles = [for pool in var.agent_pool_profiles : {
    for k, v in pool : k => (k == "nodeTaints" ? flatten(v) : v) if v != null
  }]
  os_sku = var.agent_pool_profiles[0].osSKU
  # The resource group name is the last element of the split result
  resource_group_name = element(local.resource_group_parts, length(local.resource_group_parts) - 1)
  # Split the resource group ID into parts based on '/'
  resource_group_parts               = split("/", var.resource_group_id)
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  ssh_public_key                     = var.ssh_public_key == null ? tls_private_key.rsa_key[0].public_key_openssh : var.ssh_public_key
}
