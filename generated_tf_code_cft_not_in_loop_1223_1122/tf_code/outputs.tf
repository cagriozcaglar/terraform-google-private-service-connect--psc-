output "forwarding_rule" {
  # The description of the output.
  description = "The created `google_compute_forwarding_rule` resource object for consumer endpoints. This will be null if `psc_type` is 'PRODUCER' or if no resource is created."
  # The value of the output.
  value       = length(local.consumer_forwarding_rules) > 0 ? local.consumer_forwarding_rules[0] : null
}

output "id" {
  # The description of the output.
  description = "The ID of the created Private Service Connect resource."
  # The value of the output.
  value       = length(local.all_resources) > 0 ? local.all_resources[0].id : null
}

output "ip_address" {
  # The description of the output.
  description = "The internal IP address of the created consumer PSC endpoint. This will be null if `psc_type` is 'PRODUCER' or if no resource is created."
  # The value of the output.
  value       = length(local.consumer_forwarding_rules) > 0 ? local.consumer_forwarding_rules[0].ip_address : null
}

output "self_link" {
  # The description of the output.
  description = "The self-link of the created Private Service Connect resource. For producers, this is the service attachment URI to be shared with consumers."
  # The value of the output.
  value       = length(local.all_resources) > 0 ? local.all_resources[0].self_link : null
}

output "service_attachment" {
  # The description of the output.
  description = "The created `google_compute_service_attachment` resource object for producers. This will be null if `psc_type` is not 'PRODUCER' or if no resource is created."
  # The value of the output.
  value       = length(local.producer_service_attachments) > 0 ? local.producer_service_attachments[0] : null
}
