# The main.tf file is the central part of the Terraform module, where all the resources, data sources, and modules are defined.
# It contains the logic that creates and manages the infrastructure components of the module.

locals {
  # Boolean flag to determine if the module is configured for the producer side.
  is_producer = var.psc_type == "PRODUCER"
  # Boolean flag to determine if the module is configured for the consumer side.
  is_consumer = var.psc_type == "CONSUMER"
}

# ------------------------------------------------------------------------------
# PRODUCER-SIDE RESOURCES
# ------------------------------------------------------------------------------

#
# Creates a dedicated NAT subnet for Private Service Connect.
# This subnet is required by the service attachment to perform NAT for consumer traffic.
#
resource "google_compute_subnetwork" "psc_nat_subnet" {
  # Create this resource only if in PRODUCER mode and if subnet creation is enabled.
  count = local.is_producer && var.create_psc_nat_subnet ? 1 : 0

  # The project ID where the subnet will be created.
  project = var.project_id
  # The name of the subnet. A suffix is added to the base name provided.
  name = "${var.name}-psc-nat-snet"
  # The IP address range of the subnet in CIDR format.
  ip_cidr_range = var.psc_nat_subnet_cidr
  # The region where the subnet will be created.
  region = var.region
  # The network that this subnetwork belongs to.
  network = var.network
  # The purpose of the subnet. Must be PRIVATE_SERVICE_CONNECT for use with service attachments.
  purpose = "PRIVATE_SERVICE_CONNECT"
  # A brief description of this resource.
  description = "PSC NAT subnet for the ${var.name} service attachment."

  lifecycle {
    precondition {
      condition     = var.psc_nat_subnet_cidr != null
      error_message = "The 'psc_nat_subnet_cidr' variable must be set when 'psc_type' is 'PRODUCER' and 'create_psc_nat_subnet' is true."
    }
  }
}

#
# Creates a Service Attachment to publish a service for consumption via Private Service Connect.
#
resource "google_compute_service_attachment" "producer" {
  # Use the google-beta provider as some features are only available there.
  provider = google-beta
  # Create this resource only if in PRODUCER mode.
  count = local.is_producer ? 1 : 0

  # The project ID where the service attachment will be created.
  project = var.project_id
  # The name of the service attachment.
  name = var.name
  # The region where the service attachment will be created.
  region = var.region
  # An optional description of this resource.
  description = var.description
  # If true, the PROXY protocol header will be sent to backend instances.
  enable_proxy_protocol = var.enable_proxy_protocol
  # The connection preference for this service attachment.
  # ACCEPT_AUTOMATIC automatically accepts any connection.
  # ACCEPT_MANUAL requires explicit approval for each connection.
  connection_preference = var.connection_preference
  # An array of subnets that is used for NAT translations for Private Service Connect connections.
  nat_subnets = var.create_psc_nat_subnet ? [google_compute_subnetwork.psc_nat_subnet[0].self_link] : var.psc_nat_subnets
  # The URL of the forwarding rule of the service to expose.
  target_service = var.target_service

  #
  # A list of projects or networks that are allowed to connect to this service attachment.
  # Connections from these consumers are automatically accepted.
  #
  dynamic "consumer_accept_lists" {
    # Iterate over the provided list of consumer accept configurations.
    for_each = var.consumer_accept_lists
    content {
      # The project ID or project number of the consumer project.
      project_id_or_num = consumer_accept_lists.value.project_id_or_num
      # The number of consumer forwarding rules that can connect to this service.
      connection_limit = consumer_accept_lists.value.connection_limit
    }
  }

  lifecycle {
    precondition {
      condition     = var.target_service != null
      error_message = "The 'target_service' variable must be set when 'psc_type' is 'PRODUCER'."
    }
    precondition {
      condition     = var.create_psc_nat_subnet || length(var.psc_nat_subnets) > 0
      error_message = "The 'psc_nat_subnets' variable must have at least one subnet when 'psc_type' is 'PRODUCER' and 'create_psc_nat_subnet' is false."
    }
  }
}

# ------------------------------------------------------------------------------
# CONSUMER-SIDE RESOURCES
# ------------------------------------------------------------------------------

#
# Reserves a static internal IP address for the PSC endpoint.
# Using a static IP ensures the endpoint address remains constant.
#
resource "google_compute_address" "consumer_psc_endpoint_ip" {
  # Create this resource only if in CONSUMER mode and if IP address creation is enabled.
  count = local.is_consumer && var.create_psc_endpoint_ip ? 1 : 0

  # The project ID where the address will be created.
  project = var.project_id
  # The name of the static IP address resource.
  name = "${var.name}-psc-endpoint-ip"
  # The subnetwork that this address belongs to.
  subnetwork = var.psc_endpoint_subnet
  # The type of address to reserve. Must be INTERNAL for PSC endpoints.
  address_type = "INTERNAL"
  # The region where the address will be created.
  region = var.region
  # A brief description of this resource.
  description = "Static IP address for the ${var.name} PSC endpoint."

  lifecycle {
    precondition {
      condition     = var.psc_endpoint_subnet != null
      error_message = "The 'psc_endpoint_subnet' variable must be set when 'psc_type' is 'CONSUMER'."
    }
  }
}

#
# Creates a forwarding rule that acts as the PSC endpoint in the consumer's VPC.
# This forwarding rule connects to the producer's service attachment.
#
resource "google_compute_forwarding_rule" "consumer" {
  # Create this resource only if in CONSUMER mode.
  count = local.is_consumer ? 1 : 0

  # The project ID where the forwarding rule will be created.
  project = var.project_id
  # The name of the forwarding rule.
  name = var.name
  # The region where the forwarding rule will be created.
  region = var.region
  # The network that this forwarding rule belongs to.
  network = var.network
  # The target service attachment that this forwarding rule connects to.
  # This can be a producer's service URI or a Google-managed service like 'all-apis'.
  target = var.target_service_attachment
  # The load balancing scheme. For PSC connecting to a published service, this is INTERNAL. For Google APIs, this field should not be set (null).
  load_balancing_scheme = var.consumer_load_balancing_scheme
  # The IP address that this forwarding rule will serve.
  ip_address = var.create_psc_endpoint_ip ? google_compute_address.consumer_psc_endpoint_ip[0].address : var.psc_endpoint_ip_address
  # If true, this PSC endpoint can be accessed by all regions in the VPC.
  allow_global_access = var.allow_global_access
  # An optional description of this resource.
  description = var.description

  lifecycle {
    precondition {
      condition     = var.target_service_attachment != null
      error_message = "The 'target_service_attachment' variable must be set when 'psc_type' is 'CONSUMER'."
    }
    precondition {
      condition     = var.create_psc_endpoint_ip || var.psc_endpoint_ip_address != null
      error_message = "The 'psc_endpoint_ip_address' variable must be set when 'psc_type' is 'CONSUMER' and 'create_psc_endpoint_ip' is false."
    }
    precondition {
      condition     = var.psc_endpoint_subnet != null
      error_message = "The 'psc_endpoint_subnet' variable must be set when 'psc_type' is 'CONSUMER' and creating a PSC endpoint IP."
    }
  }
}
