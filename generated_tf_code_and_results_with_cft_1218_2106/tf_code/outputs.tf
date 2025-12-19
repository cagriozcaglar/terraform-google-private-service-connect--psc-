output "service_attachment" {
  description = "The created `google_compute_service_attachment` resource."
  value       = var.create_producer_service_attachment ? google_compute_service_attachment.producer[0] : null
}

output "nat_subnet" {
  description = "The created `google_compute_subnetwork` resource for PSC NAT."
  value       = var.create_producer_service_attachment && var.create_nat_subnet ? google_compute_subnetwork.psc_nat[0] : null
}

output "consumer_endpoint" {
  description = "The created `google_compute_forwarding_rule` resource for the consumer endpoint."
  value       = var.create_consumer_endpoint ? google_compute_forwarding_rule.consumer[0] : null
}

output "consumer_static_ip_address" {
  description = "The created `google_compute_address` resource for the consumer endpoint's static IP."
  value       = var.create_consumer_endpoint && var.ip_address != null ? google_compute_address.consumer[0] : null
}

output "consumer_ip_address_value" {
  description = "The IP address of the created consumer endpoint."
  value       = var.create_consumer_endpoint ? google_compute_forwarding_rule.consumer[0].ip_address : null
}
