# TODO: Replace this dummy resource azurerm_resource_group.TODO with your module resource
data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azapi_resource.provisionedClusterInstance.id # TODO: Replace with your azurerm resource name
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.provisionedClusterInstance.id # TODO: Replace this dummy resource azurerm_resource_group.TODO with your module resource
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

data "azurerm_client_config" "current" {}

resource "azapi_resource" "connectedCluster" {
  type = "Microsoft.Kubernetes/connectedClusters@2024-01-01"
  body = {
    kind = "ProvisionedCluster"
    properties = {
      aadProfile = {
        adminGroupObjectIDs = flatten(var.rbacAdminGroupObjectIds)
        enableAzureRBAC     = var.enableAzureRBAC
        tenantID            = data.azurerm_client_config.current.tenant_id
      }
      agentPublicKeyCertificate = "" //agentPublicKeyCertificate input must be empty for Connected Cluster of Kind: Provisioned Cluster
      azureHybridBenefit        = null
      privateLinkState          = null
      provisioningState         = null
      infrastructure            = null
      distribution              = null
    }
  }
  location  = data.azurerm_resource_group.rg.location
  name      = var.name
  parent_id = data.azurerm_resource_group.rg.id

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_key_vault_secret.sshPublicKey,
    azurerm_key_vault_secret.sshPrivateKeyPem,
    terraform_data.waitAksVhdReady,
  ]

  lifecycle {
    ignore_changes = [
      identity[0],
      body.properties.azureHybridBenefit,
      body.properties.distribution,
      body.properties.infrastructure,
      body.properties.privateLinkState,
      body.properties.provisioningState,
    ]
  }
}

locals {
  agentPoolProfiles = [for pool in var.agentPoolProfiles : {
    for k, v in pool : k => (k == "nodeTaints" ? flatten(v) : v) if v != null
  }]
}

resource "azapi_resource" "provisionedClusterInstance" {
  type = "Microsoft.HybridContainerService/provisionedClusterInstances@2024-01-01"
  body = {
    extendedLocation = {
      name = var.customLocationId
      type = "CustomLocation"
    }
    properties = {
      agentPoolProfiles = flatten(local.agentPoolProfiles)
      cloudProviderProfile = {
        infraNetworkProfile = {
          vnetSubnetIds = [
            var.logicalNetworkId,
          ]
        }
      }
      controlPlane = {
        count  = var.controlPlaneCount
        vmSize = var.controlPlaneVmSize
        controlPlaneEndpoint = {
          hostIP = var.controlPlaneIp
        }
      }
      kubernetesVersion = var.kubernetesVersion
      linuxProfile = {
        ssh = {
          publicKeys = [
            {
              keyData = local.sshPublicKey
            },
          ]
        }
      }
      networkProfile = {
        podCidr       = var.podCidr
        networkPolicy = "calico"
        loadBalancerProfile = {
          // acctest0002 network only supports a LoadBalancer count of 0
        }
      }
      storageProfile = {
        smbCsiDriver = {
          enabled = true
        }
        nfsCsiDriver = {
          enabled = true
        }
      }
      clusterVMAccessProfile = {}
      licenseProfile         = { azureHybridBenefit = "False" }
    }
  }
  name      = "default"
  parent_id = azapi_resource.connectedCluster.id

  depends_on = [azapi_resource.connectedCluster]

  lifecycle {
    ignore_changes = [
      body.properties.autoScalerProfile,
      body.properties.networkProfile.podCidr,
      body.properties.provisioningStateTransitionTime,
      body.properties.provisioningStateUpdatedTime,
    ]
  }
}
