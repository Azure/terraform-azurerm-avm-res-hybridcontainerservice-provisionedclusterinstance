locals {
  aad_profile_full = var.enable_azure_rbac != null ? {
    adminGroupObjectIDs = flatten(var.rbac_admin_group_object_ids)
    enableAzureRBAC     = var.enable_azure_rbac
    tenantID            = var.tenant_id == "" ? data.azurerm_client_config.current[0].tenant_id : var.tenant_id
    } : {
    adminGroupObjectIDs = null
    enableAzureRBAC     = null
    tenantID            = null
  }
  aad_profile_omit_null = { for k, v in local.aad_profile_full : k => v if v != null }
  agent_pool_profiles = [for pool in var.agent_pool_profiles : {
    for k, v in pool : k => (k == "nodeTaints" ? flatten(v) : v) if v != null
  }]
  kubernetesVersion = (var.kubernetes_version == null || var.kubernetes_version == "") ? "[PLACEHOLDER]" : var.kubernetes_version
  oidc_profile_full = var.enable_oidc_issuer != null ? {
    enabled = var.enable_oidc_issuer
    } : {
    enabled = null
  }
  oidc_profile_omit_null = var.enable_oidc_issuer == true ? { for k, v in local.oidc_profile_full : k => v if v != null } : null
  os_sku                 = var.agent_pool_profiles[0].osSKU
  properties_full = {
    arcAgentProfile = {
      agentAutoUpgrade = "Enabled"
    }
    aadProfile                = local.aad_profile_omit_null
    agentPublicKeyCertificate = "" # agentPublicKeyCertificate input must be empty for Connected Cluster of Kind: Provisioned Cluster
    azureHybridBenefit        = null
    privateLinkState          = null
    provisioningState         = null
    infrastructure            = null
    distribution              = null
    securityProfile = {
      workloadIdentity = {
        enabled = var.enable_workload_identity
      }
    }
    oidcIssuerProfile = {
      enabled = var.enable_oidc_issuer
    }
  }
  properties_omit_null = { for k, v in local.properties_full : k => v if v != null }
  # The resource group name is the last element of the split result
  resource_group_name = element(local.resource_group_parts, length(local.resource_group_parts) - 1)
  # Split the resource group ID into parts based on '/'
  resource_group_parts               = split("/", var.resource_group_id)
  role_definition_resource_substring = "/providers/Microsoft.Authorization/roleDefinitions"
  security_profile_full = var.enable_workload_identity != null ? {
    workloadIdentity = {
      enabled = var.enable_workload_identity
    }
    } : {
    workloadIdentity = {
      enabled = null
    }
  }
  security_profile_omit_null = var.enable_workload_identity == true ? { for k, v in local.security_profile_full : k => v if v.enabled != null } : null
  ssh_public_key             = var.ssh_public_key == null ? tls_private_key.rsa_key[0].public_key_openssh : var.ssh_public_key
}
