resource "terraform_data" "replacement" {
  count = var.is_exported ? 0 : 1
  input = local.resource_group_name
}

# This is a known issue for arc aks, it need to wait for the kubernate vhd ready to deploy aks
resource "terraform_data" "wait_aks_vhd_ready" {
  count = var.is_exported ? 0 : 1
  provisioner "local-exec" {
    command     = "${local.program} -ExecutionPolicy Bypass -NoProfile -File ${path.module}/readiness.ps1 -customLocationResourceId ${var.custom_location_id} -kubernetesVersion ${local.kubernetes_version} -osSku ${local.os_sku}"
    interpreter = [local.is_windows ? "PowerShell" : "pwsh", "-Command"]
  }

  lifecycle {
    replace_triggered_by = [terraform_data.replacement[0]]
  }
}
