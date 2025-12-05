# This is a known issue for arc aks, it need to wait for the kubernate vhd ready to deploy aks
resource "terraform_data" "wait_aks_vhd_ready" {
  count = var.is_exported ? 0 : 1

  # Always replace on every apply to ensure VHD readiness is checked
  triggers_replace = timestamp()

  provisioner "local-exec" {
    command     = "${local.program} -ExecutionPolicy Bypass -NoProfile -File ${path.module}/readiness.ps1 -customLocationResourceId ${var.custom_location_id} -kubernetesVersion ${local.kubernetes_version} -osSku ${local.os_sku}"
    interpreter = [local.is_windows ? "PowerShell" : "pwsh", "-Command"]
  }
}
