resource "tls_private_key" "rsa_key" {
  count = var.ssh_public_key == null ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_key_vault_secret" "ssh_public_key" {
  count = var.ssh_public_key == null ? 1 : 0

  key_vault_id = var.ssh_key_vault_id
  name         = var.ssh_public_key_secret_name
  tags         = {}
  value        = tls_private_key.rsa_key[0].public_key_openssh
}

resource "azurerm_key_vault_secret" "ssh_private_key_pem" {
  count = var.ssh_public_key == null ? 1 : 0

  key_vault_id = var.ssh_key_vault_id
  name         = var.ssh_private_key_pem_secret_name
  tags         = {}
  value        = tls_private_key.rsa_key[0].private_key_pem
}
