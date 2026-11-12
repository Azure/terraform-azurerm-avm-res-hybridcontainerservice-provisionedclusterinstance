locals {
  resource_group_id            = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  effective_custom_location_id = var.custom_location_id != null ? var.custom_location_id : data.azapi_resource.customlocation["lookup"].id
  effective_logical_network_id = var.logical_network_id != null ? var.logical_network_id : data.azapi_resource.logical_network["lookup"].id
}
