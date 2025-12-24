# The service attachment resource that is created.
output "service_attachment" {
  description = "The created `google_compute_service_attachment` resource. This is only available when `psc_type` is 'producer'."
  value       = one(google_compute_service_attachment.producer_attachment[*])
}

# The service attachment URI.
output "service_attachment_uri" {
  description = "The URI of the created service attachment. Consumers will use this to connect. This is only available when `psc_type` is 'producer'."
  value       = try(google_compute_service_attachment.producer_attachment[0].self_link, null)
}

# The NAT subnets.
output "nat_subnets" {
  description = "A map of the created `google_compute_subnetwork` resources for PSC NAT. Keys are the CIDR ranges. This is only available when `psc_type` is 'producer'."
  value       = google_compute_subnetwork.psc_nat_subnets
}

# The consumer forwarding rule.
output "consumer_forwarding_rule" {
  description = "The created `google_compute_forwarding_rule` resource that acts as the PSC endpoint. This is only available when `psc_type` is 'consumer'."
  value       = one(google_compute_forwarding_rule.consumer_endpoint[*])
}

# The consumer endpoint IP address.
output "consumer_endpoint_ip_address" {
  description = "The internal IP address of the consumer PSC endpoint. This is only available when `psc_type` is 'consumer'."
  value       = try(google_compute_forwarding_rule.consumer_endpoint[0].ip_address, null)
}

# The consumer address resource.
output "consumer_address" {
  description = "The created `google_compute_address` resource for the consumer endpoint. This is only available when `psc_type` is 'consumer' and `consumer_create_address` is true."
  value       = one(google_compute_address.consumer_endpoint_ip[*])
}
