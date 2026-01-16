# The outputs.tf file is used to declare the output values of the module.
# These outputs can be used by other parts of the Terraform configuration to access information about the resources created by the module.
# For example, you can output the ID of a created resource, which can then be used as an input to another module.

output "service_attachment" {
  description = "The created Google Compute Service Attachment resource. This will be null if psc_type is 'CONSUMER'."
  value       = try(google_compute_service_attachment.producer[0], null)
}

output "psc_endpoint" {
  description = "The created Google Compute Forwarding Rule resource, which acts as the PSC endpoint. This will be null if psc_type is 'PRODUCER'."
  value       = try(google_compute_forwarding_rule.consumer[0], null)
}

output "psc_endpoint_ip_address" {
  description = "The internal IP address of the created PSC endpoint. This will be null if psc_type is 'PRODUCER'."
  value       = try(google_compute_forwarding_rule.consumer[0].ip_address, null)
}

output "psc_nat_subnet" {
  description = "The created PSC NAT subnet for the service attachment. This will be null if psc_type is 'CONSUMER' or if an existing subnet was used."
  value       = try(google_compute_subnetwork.psc_nat_subnet[0], null)
}
