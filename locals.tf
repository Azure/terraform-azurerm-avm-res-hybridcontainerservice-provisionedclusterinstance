locals {
  agent_pool_profiles = [for pool in var.agent_pool_profiles : {
    for k, v in pool : k => (k == "nodeTaints" ? flatten(v) : v) if v != null
  }]
  os_sku                             = var.agent_pool_profiles[0].osSKU
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  ssh_public_key                     = var.ssh_public_key == null ? tls_private_key.rsa_key[0].public_key_openssh : var.ssh_public_key
}
