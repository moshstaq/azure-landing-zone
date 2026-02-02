output "load_balancer_public_ip" {
  description = "Public IP of the Load Balancer"
  value       = azurerm_public_ip.lb.ip_address
}

output "vm2_private_ip" {
  description = "Private IP of vm-dev-002"
  value       = azurerm_network_interface.vm2.private_ip_address
}

output "backend_pool_id" {
  description = "Backend pool ID"
  value       = azurerm_lb_backend_address_pool.web.id
}

output "test_url" {
  description = "URL to test load balancer"
  value       = "http://${azurerm_public_ip.lb.ip_address}"
}
