# required AVM resources interfaces
resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azapi_resource.connected_cluster.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azapi_resource.connected_cluster.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}

data "azurerm_client_config" "current" {
  count = var.tenant_id == "" ? 1 : 0
}

resource "azapi_resource" "connected_cluster" {
  type = "Microsoft.Kubernetes/connectedClusters@2024-07-15-preview"
  body = {
    kind       = "ProvisionedCluster"
    properties = local.properties_with_nulls
  }
  location  = var.location
  name      = var.name
  parent_id = var.resource_group_id
  tags      = var.tags

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_key_vault_secret.ssh_public_key,
    azurerm_key_vault_secret.ssh_private_key_pem,
    terraform_data.wait_aks_vhd_ready,
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

resource "azapi_resource" "provisioned_cluster_instance" {
  type = "Microsoft.HybridContainerService/provisionedClusterInstances@2024-01-01"
  body = {
    extendedLocation = {
      name = var.custom_location_id
      type = "CustomLocation"
    }
    properties = {
      agentPoolProfiles = flatten(local.agent_pool_profiles)
      cloudProviderProfile = {
        infraNetworkProfile = {
          vnetSubnetIds = [
            var.logical_network_id,
          ]
        }
      }
      controlPlane = {
        count  = var.control_plane_count
        vmSize = var.control_plane_vm_size
        controlPlaneEndpoint = {
          hostIP = var.control_plane_ip
        }
      }
      kubernetesVersion = var.kubernetes_version
      linuxProfile = {
        ssh = {
          publicKeys = [
            {
              keyData = local.ssh_public_key
            },
          ]
        }
      }
      networkProfile = {
        podCidr       = var.pod_cidr
        networkPolicy = "calico"
        loadBalancerProfile = {
          # acctest0002 network only supports a LoadBalancer count of 0
          count = 0
        }
      }
      storageProfile = {
        smbCsiDriver = {
          enabled = var.smb_csi_driver_enabled
        }
        nfsCsiDriver = {
          enabled = var.nfs_csi_driver_enabled
        }
      }
      clusterVMAccessProfile = {}
      licenseProfile         = { azureHybridBenefit = var.azure_hybrid_benefit }
    }
  }
  name      = "default"
  parent_id = azapi_resource.connected_cluster.id

  depends_on = [azapi_resource.connected_cluster]

  lifecycle {
    ignore_changes = [
      body.properties.autoScalerProfile,
      body.properties.networkProfile.podCidr,
      body.properties.provisioningStateTransitionTime,
      body.properties.provisioningStateUpdatedTime,
    ]
  }
}

resource "azapi_resource" "agent_pool" {
  count    = var.create_additional_nodepool ? 1 : 0
  for_each = var.additional_nodepools

  type = "Microsoft.HybridContainerService/provisionedClusterInstances/agentPools@2024-01-01"
  body = {
    extendedLocation = {
      name = var.custom_location_id
      type = "CustomLocation"
    }
    properties = {
      count             = each.value.count
      enableAutoScaling = each.value.enableAutoScaling
      nodeLabels        = each.value.nodeLabels
      nodeTaints        = each.value.nodeTaints
      maxPods           = each.value.maxPods
      osSKU             = each.value.osSKU
      osType            = each.value.osType
      vmSize            = each.value.vmSize
    }
  }
  name      = each.key
  parent_id = resource.azapi_resource.provisioned_cluster_instance.id
}
