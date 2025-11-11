# output "public_ip_address" {
#   value = azurerm_public_ip.public_ip.ip_address
# }

output "public_ip_address" {
  value = [
        for key in azurerm_public_ip.public_ip : key.public_ip_address
  ]
}