output "aksCluster" {
  description = "AKS Arc Cluster instance"
  value       = azapi_resource.connectedCluster
}

output "resource_id" {
  description = "AKS Arc Provisioned Cluster instance"
  value       = azapi_resource.provisionedClusterInstance
}

# Module owners should include the full resource via a 'resource' output
# https://azure.github.io/Azure-Verified-Modules/specs/terraform/#id-tffr2---category-outputs---additional-terraform-outputs
output "rsaPrivateKey" {
  sensitive = true
  value     = var.sshPublicKey == null ? tls_private_key.rsaKey[0].private_key_pem : ""
}
