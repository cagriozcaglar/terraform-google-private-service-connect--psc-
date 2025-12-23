# This file contains the output definitions for the module.

output "endpoint_forwarding_rule_id" {
  # The description of the output value.
  description = "The resource ID of the created PSC endpoint forwarding rule. This will be null if psc_type is 'producer' or if the endpoint is not created."
  # The value of the output. Returns the ID of the forwarding rule if it was created, otherwise null.
  value = one(google_compute_forwarding_rule.psc_endpoint[*].id)
}

output "endpoint_ip_address" {
  # The description of the output value.
  description = "The IP address of the created PSC endpoint. This will be null if psc_type is 'producer' or if the endpoint is not created."
  # The value of the output. Returns the IP address of the endpoint if it was created, otherwise null.
  value = one(google_compute_address.endpoint_ip[*].address)
}

output "psc_nat_subnet_id" {
  # The description of the output value.
  description = "The resource ID of the created PSC NAT subnet. This will be null if psc_type is 'consumer' or 'google_apis' or if the subnet is not created."
  # The value of the output. Returns the ID of the NAT subnet if it was created, otherwise null.
  value = one(google_compute_subnetwork.psc_nat_subnet[*].id)
}

output "service_attachment_id" {
  # The description of the output value.
  description = "The resource ID of the created service attachment. This will be null if psc_type is 'consumer' or 'google_apis' or if the service attachment is not created."
  # The value of the output. Returns the ID of the service attachment if it was created, otherwise null.
  value = one(google_compute_service_attachment.producer_service[*].id)
}
