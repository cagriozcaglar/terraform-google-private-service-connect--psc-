# The IP address of the PSC endpoint. Only available when psc_type is 'CONSUMER'.
output "endpoint_ip_address" {
  description = "The IP address of the PSC endpoint. Only available when psc_type is 'CONSUMER'."
  value       = try(one(google_compute_forwarding_rule.consumer[*].ip_address), null)
}

# The created PSC endpoint forwarding rule resource. Only available when psc_type is 'CONSUMER'.
output "forwarding_rule" {
  description = "The created PSC endpoint forwarding rule resource. Only available when psc_type is 'CONSUMER'."
  value       = try(one(google_compute_forwarding_rule.consumer), null)
}

# The created static IP address resource for the PSC endpoint. Only available when psc_type is 'CONSUMER' and a value for 'ip_address' is not provided.
output "ip_address_resource" {
  description = "The created static IP address resource for the PSC endpoint. Only available when psc_type is 'CONSUMER' and a value for 'ip_address' is not provided."
  value       = try(one(google_compute_address.consumer), null)
}

# The PSC NAT subnet created by this module. Only available when psc_type is 'PRODUCER' and create_nat_subnet is true.
output "nat_subnet" {
  description = "The PSC NAT subnet created by this module. Only available when psc_type is 'PRODUCER' and create_nat_subnet is true."
  value       = try(one(google_compute_subnetwork.psc_nat), null)
}

# The created PSC service attachment resource. Only available when psc_type is 'PRODUCER'.
output "service_attachment" {
  description = "The created PSC service attachment resource. Only available when psc_type is 'PRODUCER'."
  value       = try(one(google_compute_service_attachment.producer), null)
}

# The URI of the created service attachment, which is used by consumers. Only available when psc_type is 'PRODUCER'.
output "service_attachment_uri" {
  description = "The URI of the created service attachment, which is used by consumers. Only available when psc_type is 'PRODUCER'."
  value       = try(one(google_compute_service_attachment.producer[*].self_link), null)
}
