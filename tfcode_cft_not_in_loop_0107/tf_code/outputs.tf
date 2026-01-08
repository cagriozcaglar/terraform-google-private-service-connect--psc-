output "service_attachment" {
  description = "The created service attachment resource. Only available in producer mode."
  value       = try(google_compute_service_attachment.producer_service[0], null)
}

output "consumer_forwarding_rule" {
  description = "The created consumer forwarding rule resource. Only available in consumer modes."
  value = try(
    coalesce(
      try(google_compute_forwarding_rule.psc_endpoint[0], null),
      try(google_compute_forwarding_rule.psc_google_apis_endpoint[0], null)
    ),
    null
  )
}

output "consumer_ip_address" {
  description = "The IP address of the created consumer endpoint. Only available in consumer modes."
  value = try(coalesce(
    try(google_compute_forwarding_rule.psc_endpoint[0].ip_address, null),
    try(google_compute_forwarding_rule.psc_google_apis_endpoint[0].ip_address, null)
  ), null)
}

output "nat_subnets" {
  description = "A map of the created PSC NAT subnets, keyed by their self-link. Only available in producer mode."
  value       = local.is_producer_mode ? { for s in google_compute_subnetwork.psc_nat_subnets : s.self_link => s } : {}
}

output "psc_connection_id" {
  description = "The connection ID of the PSC forwarding rule. Only available in consumer service mode."
  value       = try(google_compute_forwarding_rule.psc_endpoint[0].psc_connection_id, null)
}
