# <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
# <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

# Local variables for simplifying conditional logic.
locals {
  # Determines if the consumer target is a well-known Google API bundle.
  is_google_api_target = var.psc_type == "consumer" ? contains(["all-apis", "vpc-sc"], var.consumer_target_service) : false

  # If consumer_allow_psc_global_access is not explicitly set, automatically enable it for Google API targets.
  consumer_global_access = var.consumer_allow_psc_global_access == null ? local.is_google_api_target : var.consumer_allow_psc_global_access

  # Determines the IP address to use for the consumer forwarding rule.
  # If creating a new address, use its self_link. Otherwise, use the provided address.
  consumer_fr_ip_address = var.psc_type == "consumer" ? (
    var.consumer_create_address ? one(google_compute_address.consumer_endpoint_ip[*]).self_link : var.consumer_ip_address
  ) : null
}

# --- PRODUCER RESOURCES ---

# Create one or more NAT subnets for the service attachment.
# These subnets are dedicated to PSC and used for NATing traffic from consumers.
resource "google_compute_subnetwork" "psc_nat_subnets" {
  # Create these subnets only if the module is in 'producer' mode.
  for_each = var.psc_type == "producer" ? toset(var.producer_nat_subnets) : toset([])

  # The GCP project ID where the subnet will be created.
  project = var.project_id

  # The name of the NAT subnet. Derived from the module name and a sanitized CIDR block.
  name = "${var.name}-nat-${replace(each.key, "/.", "-")}"

  # The region for the subnet.
  region = var.region

  # The IP CIDR range for this subnet.
  ip_cidr_range = each.key

  # The network this subnet belongs to.
  network = var.network

  # The purpose of this subnet must be PRIVATE_SERVICE_CONNECT.
  purpose = "PRIVATE_SERVICE_CONNECT"

  # A description for the subnet.
  description = var.description != null ? var.description : "PSC NAT subnet for ${var.name}"
}

# The Service Attachment resource publishes the producer's service.
resource "google_compute_service_attachment" "producer_attachment" {
  # Create this resource only if the module is in 'producer' mode.
  count = var.psc_type == "producer" ? 1 : 0

  # The GCP project ID where the service attachment will be created.
  project = var.project_id

  # The name of the service attachment.
  name = var.name

  # The region for the service attachment.
  region = var.region

  # An optional description for the service attachment.
  description = var.description

  # Determines how consumer connection requests are handled.
  connection_preference = var.producer_connection_preference

  # The list of NAT subnets to use for this service attachment.
  nat_subnets = [for s in google_compute_subnetwork.psc_nat_subnets : s.self_link]

  # The self-link of the Internal Load Balancer's forwarding rule that fronts the service.
  target_service = var.producer_target_service

  # Specifies whether the PROXY protocol is enabled.
  enable_proxy_protocol = var.producer_enable_proxy_protocol

  # A list of projects that are allowed to connect to this service attachment.
  dynamic "consumer_accept_lists" {
    for_each = var.producer_consumer_accept_lists
    content {
      project_id_or_num = consumer_accept_lists.value.project_id_or_num
      connection_limit  = consumer_accept_lists.value.connection_limit
    }
  }
}

# --- CONSUMER RESOURCES ---

# Optionally create a static internal IP address for the PSC endpoint.
resource "google_compute_address" "consumer_endpoint_ip" {
  # Create this resource only if in 'consumer' mode and address creation is enabled.
  count = var.psc_type == "consumer" && var.consumer_create_address ? 1 : 0

  # The GCP project ID where the address will be created.
  project = var.project_id

  # The name of the address resource.
  name = "${var.name}-ip"

  # The region for the address.
  region = var.region

  # The subnetwork this address belongs to.
  subnetwork = var.consumer_subnetwork

  # The type of address must be INTERNAL for PSC endpoints.
  address_type = "INTERNAL"

  # A specific IP address to reserve from the subnetwork's range.
  address = var.consumer_ip_address

  # An optional description for the address.
  description = var.description != null ? var.description : "Static IP for PSC endpoint ${var.name}"
}

# The forwarding rule that acts as the PSC endpoint in the consumer's VPC.
resource "google_compute_forwarding_rule" "consumer_endpoint" {
  # Create this resource only if the module is in 'consumer' mode.
  count = var.psc_type == "consumer" ? 1 : 0

  # The GCP project ID where the forwarding rule will be created.
  project = var.project_id

  # The name of the forwarding rule (PSC endpoint).
  name = var.name

  # The region for the forwarding rule.
  region = var.region

  # The network where the endpoint will reside.
  network = var.network

  # The subnetwork where the endpoint will get its IP address.
  subnetwork = var.consumer_subnetwork

  # The IP address for the endpoint. This is determined by the local variable.
  ip_address = local.consumer_fr_ip_address

  # The target of the PSC connection. This is the service attachment URI or a Google API bundle.
  target = var.consumer_target_service

  # This must be an empty string for PSC consumer endpoints.
  load_balancing_scheme = ""

  # Whether to allow global access to this PSC endpoint.
  # This is required for connecting to global Google APIs.
  allow_psc_global_access = local.consumer_global_access

  # An optional description for the forwarding rule.
  description = var.description
}
