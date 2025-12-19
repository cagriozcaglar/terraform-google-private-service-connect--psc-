# This module is designed to provision Private Service Connect (PSC) resources in Google Cloud.
# It supports both producer-side configurations (publishing a service via a Service Attachment)
# and consumer-side configurations (accessing a service via a Forwarding Rule endpoint).
# The module ensures that you can create one type of configuration at a time by setting
# either `create_producer_service_attachment` or `create_consumer_endpoint` to true.
#
# For Producers:
# - Creates a `google_compute_service_attachment`.
# - Optionally creates a dedicated NAT subnet with the `PRIVATE_SERVICE_CONNECT` purpose.
# - Supports both automatic and manual connection acceptance policies.
#
# For Consumers:
# - Creates a `google_compute_forwarding_rule` that acts as the PSC endpoint.
# - Optionally reserves a static internal IP address for the endpoint.
#
# <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
# <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

resource "google_compute_subnetwork" "psc_nat" {
  # Creates a dedicated NAT subnet for the PSC Service Attachment.
  # This is a requirement for producers publishing a service.
  count = var.create_producer_service_attachment && var.create_nat_subnet ? 1 : 0

  project                  = var.project_id
  name                     = var.nat_subnet_name
  ip_cidr_range            = var.nat_subnet_cidr_range
  region                   = var.region
  network                  = var.producer_network
  purpose                  = "PRIVATE_SERVICE_CONNECT"
  private_ip_google_access = true
  description              = "NAT subnet for the Private Service Connect attachment ${var.name}"
}

resource "google_compute_service_attachment" "producer" {
  # Creates the Service Attachment to publish an internal service (ILB) for consumption by other VPCs.
  count = var.create_producer_service_attachment ? 1 : 0

  project               = var.project_id
  name                  = var.name
  region                = var.region
  description           = "PSC Service Attachment for ${var.name}"
  enable_proxy_protocol = var.enable_proxy_protocol
  connection_preference = var.connection_preference
  target_service        = var.target_service
  nat_subnets           = var.create_nat_subnet ? [google_compute_subnetwork.psc_nat[0].self_link] : var.nat_subnets_self_links

  # Dynamic block to configure the consumer accept list for manual connection preferences.
  dynamic "consumer_accept_lists" {
    for_each = var.consumer_accept_list
    content {
      # The project ID or number that is allowed to connect to this service.
      project_id_or_num = consumer_accept_lists.value.project_id_or_num
      # The number of connections from this project that are allowed to connect to this service.
      connection_limit = consumer_accept_lists.value.connection_limit
    }
  }
}

resource "google_compute_address" "consumer" {
  # Reserves a static internal IP address for the consumer PSC endpoint.
  # This is created only if a specific IP address is provided via `var.ip_address`.
  count = var.create_consumer_endpoint && var.ip_address != null ? 1 : 0

  project      = var.project_id
  name         = "${var.name}-ip-address"
  subnetwork   = var.consumer_subnetwork
  address_type = "INTERNAL"
  address      = var.ip_address
  region       = var.region
  description  = "Static IP address for the PSC endpoint ${var.name}"
}

resource "google_compute_forwarding_rule" "consumer" {
  # Creates the Forwarding Rule which acts as the PSC endpoint in the consumer's VPC,
  # connecting to the producer's service attachment.
  count = var.create_consumer_endpoint ? 1 : 0

  project    = var.project_id
  name       = var.name
  region     = var.region
  network    = var.consumer_network
  subnetwork = var.consumer_subnetwork
  target     = var.service_attachment_uri
  ip_address = var.ip_address != null ? google_compute_address.consumer[0].address : null
}
