output "aks_cluster" {
  description = "AKS Arc Cluster instance"
  value       = azapi_resource.connected_cluster
}

output "resource_id" {
  description = "AKS Arc Provisioned Cluster instance"
  value       = azapi_resource.provisioned_cluster_instance.id
}

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "rsa_private_key" {
  description = "The RSA private key"
  sensitive   = true
  value       = var.ssh_public_key == null ? tls_private_key.rsa_key[0].private_key_pem : ""
}
