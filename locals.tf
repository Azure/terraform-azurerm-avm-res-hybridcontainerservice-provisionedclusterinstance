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
  additional_nodepools = [for pool in var.additional_nodepools : {
    for k, v in {
      count             = pool.count
      enableAutoScaling = pool.enableAutoScaling
      nodeLabels        = pool.nodeLabels
      nodeTaints        = pool.nodeTaints
      maxPods           = pool.maxPods
      osSKU             = pool.osSKU
      osType            = pool.osType
      vmSize            = pool.vmSize
    } : k => v if v != null
  }]
  agent_pool_profiles = [for pool in var.agent_pool_profiles : {
    for k, v in pool : k => (k == "nodeTaints" ? flatten(v) : v) if v != null
  }]
  extended_location_full = {
    for idx, pool in var.additional_nodepools : idx => (
      pool.original != true ? {
        name = var.custom_location_id
        type = "CustomLocation"
        } : {
        name = null
        type = null
      }
    )
  }
  extended_location_omit_null = {
    for k, v in local.extended_location_full : k => (
      alltrue([for _, val in v : val == null]) ? null : {
        for key, val in v : key => val if val != null
      }
    )
  }
  is_windows         = length(regexall("^[a-z]:", lower(abspath(path.root)))) > 0
  kubernetes_version = (var.kubernetes_version == null || var.kubernetes_version == "") ? "[PLACEHOLDER]" : var.kubernetes_version
  nodepool_bodies_full = {
    for k, v in local.extended_location_omit_null : k => {
      properties = merge(local.additional_nodepools[k], {
        status = null
      })
      extendedLocation = v
    }
  }
  nodepool_bodies_omit_null = {
    for k, v in local.nodepool_bodies_full : k => {
      for key, val in v : key => val if val != null
    }
  }
  oidc_profile_full = var.enable_oidc_issuer != null ? {
    enabled = var.enable_oidc_issuer
    } : {
    enabled = null
  }
  oidc_profile_omit_null = var.enable_oidc_issuer == true ? { for k, v in local.oidc_profile_full : k => v if v != null } : null
  os_sku                 = var.agent_pool_profiles[0].osSKU
  program                = local.is_windows ? "powershell.exe" : "pwsh"
  properties_full = {
    arcAgentProfile = {
      agentAutoUpgrade = "Enabled"
    }
    aadProfile                = local.aad_profile_omit_null
    agentPublicKeyCertificate = "" # agentPublicKeyCertificate input must be empty for Connected Cluster of Kind: Provisioned Cluster
    securityProfile           = local.security_profile_omit_null
    oidcIssuerProfile         = local.oidc_profile_omit_null
  }
  properties_omit_null = { for k, v in local.properties_full : k => v if v != null }
  properties_with_nulls = merge(local.properties_omit_null, {
    azureHybridBenefit = null
    privateLinkState   = null
    provisioningState  = null
    infrastructure     = null
    distribution       = null
  })
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
