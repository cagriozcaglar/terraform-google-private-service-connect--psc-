# Local variables for conditional logic and resource naming.
locals {
  # Determines if the module is in PRODUCER mode.
  is_producer = var.psc_type == "PRODUCER"
  # Determines if the module is in CONSUMER mode.
  is_consumer = var.psc_type == "CONSUMER"

  # Determines if the consumer endpoint is targeting a Google API bundle.
  # Use try() to prevent errors when var.target_service_attachment is null.
  is_google_apis_consumer = local.is_consumer ? try(contains(["all-apis", "vpc-sc"], var.target_service_attachment), false) : false

  # If creating a NAT subnet, its name will be based on the service attachment name.
  nat_subnet_name = local.is_producer && var.create_nat_subnet && var.name != null ? "${var.name}-nat" : null
  # If creating an IP address, its name will be based on the endpoint name.
  ip_address_name = local.is_consumer && var.ip_address == null && var.name != null ? "${var.name}-ip" : null
}

#
# PRODUCER (SERVICE ATTACHMENT) RESOURCES
#

# Creates a dedicated NAT subnet for PSC. This is required for service attachments.
resource "google_compute_subnetwork" "psc_nat" {
  # Create this resource only in PRODUCER mode and if requested.
  count = local.is_producer && var.create_nat_subnet ? 1 : 0

  # The project ID where the subnetwork will be created.
  project = var.project_id
  # The name of the subnetwork.
  name = local.nat_subnet_name
  # The IP address range of the subnetwork.
  ip_cidr_range = var.nat_subnet_ip_cidr_range
  # The region where the subnetwork will be created.
  region = var.region
  # The network to which this subnetwork belongs.
  network = var.network
  # The purpose of this subnetwork. Must be 'PRIVATE_SERVICE_CONNECT'.
  purpose = "PRIVATE_SERVICE_CONNECT"
  # An optional description of this subnetwork.
  description = "PSC NAT subnet for ${var.name}"

  # Preconditions to ensure required variables are set.
  lifecycle {
    precondition {
      # Checks if required variables for producer mode are set.
      condition     = var.project_id != null && var.name != null && var.region != null && var.network != null
      # Error message to display if the condition is not met.
      error_message = "When creating a producer NAT subnet, 'project_id', 'name', 'region', and 'network' variables must be set."
    }
    precondition {
      # Checks if the NAT subnet CIDR range is provided when creating a new NAT subnet.
      condition     = var.nat_subnet_ip_cidr_range != null
      # Error message to display if the condition is not met.
      error_message = "The 'nat_subnet_ip_cidr_range' variable must be set when 'create_nat_subnet' is true."
    }
  }
}

# Creates the PSC Service Attachment to publish a service.
resource "google_compute_service_attachment" "producer" {
  # Create this resource only in PRODUCER mode.
  count = local.is_producer ? 1 : 0

  # The project ID where the service attachment will be created.
  project = var.project_id
  # The name of the service attachment.
  name = var.name
  # The region where the service attachment will be created.
  region = var.region
  # An optional description of this service attachment.
  description = var.description
  # Enables the PROXY protocol to preserve client source IP.
  enable_proxy_protocol = var.enable_proxy_protocol
  # The connection preference, either 'ACCEPT_AUTOMATIC' or 'ACCEPT_MANUAL'.
  connection_preference = var.connection_preference
  # The list of NAT subnets to use for this service attachment.
  # It combines any user-provided subnets with the one created by this module.
  nat_subnets = concat(var.nat_subnets, [for s in google_compute_subnetwork.psc_nat : s.self_link])
  # The target service (an ILB forwarding rule) to be exposed.
  target_service = var.target_service
  # A list of projects to reject connections from.
  consumer_reject_lists = var.consumer_reject_lists

  # A list of projects from which connections are accepted.
  dynamic "consumer_accept_lists" {
    # Iterate over the provided list of consumer accept configurations.
    for_each = var.consumer_accept_lists
    # Defines the content of the dynamic block.
    content {
      # The project ID or number to accept connections from.
      project_id_or_num = consumer_accept_lists.value.project_id_or_num
      # The number of connections to allow from the consumer project.
      connection_limit = consumer_accept_lists.value.connection_limit
    }
  }

  # Preconditions to ensure required variables are set and resources are available.
  lifecycle {
    precondition {
      # Checks if required variables for producer mode are set.
      condition     = var.project_id != null && var.name != null && var.region != null
      # Error message to display if the condition is not met.
      error_message = "When creating a producer service attachment, 'project_id', 'name', and 'region' variables must be set."
    }
    precondition {
      # Checks if the target service is provided.
      condition     = var.target_service != null
      # Error message to display if the condition is not met.
      error_message = "The 'target_service' variable must be set when psc_type is 'PRODUCER'."
    }
    precondition {
      # Checks if at least one NAT subnet is configured.
      condition     = length(concat(var.nat_subnets, [for s in google_compute_subnetwork.psc_nat : s.self_link])) > 0
      # Error message to display if the condition is not met.
      error_message = "At least one NAT subnet must be provided via 'nat_subnets' or created by setting 'create_nat_subnet' to true."
    }
  }
}

#
# CONSUMER (ENDPOINT) RESOURCES
#

# Reserves a static internal IP address for the PSC endpoint.
resource "google_compute_address" "consumer" {
  # Create this resource only in CONSUMER mode and if an existing IP is not provided.
  count = local.is_consumer && var.ip_address == null ? 1 : 0

  # The project ID where the address will be created.
  project = var.project_id
  # The name of the address resource.
  name = local.ip_address_name
  # The subnetwork that this address will be allocated from.
  subnetwork = var.subnetwork
  # The type of address to reserve. Must be 'INTERNAL' for PSC.
  address_type = "INTERNAL"
  # The region where the address will be created.
  region = var.region
  # An optional description of this address.
  description = var.description

  # Preconditions to ensure required variables are set.
  lifecycle {
    precondition {
      # Checks if required variables for consumer mode are set.
      condition     = var.project_id != null && var.name != null && var.region != null && var.subnetwork != null
      # Error message to display if the condition is not met.
      error_message = "When creating a consumer IP address, 'project_id', 'name', 'region', and 'subnetwork' variables must be set."
    }
  }
}

# Creates the PSC endpoint as an internal forwarding rule.
resource "google_compute_forwarding_rule" "consumer" {
  # Create this resource only in CONSUMER mode.
  count = local.is_consumer ? 1 : 0

  # The project ID where the forwarding rule will be created.
  project = var.project_id
  # The name of the forwarding rule.
  name = var.name
  # The region where the forwarding rule will be created.
  region = var.region
  # An optional description of this forwarding rule.
  description = var.description
  # The load balancing scheme. Must be 'INTERNAL' for Google APIs and 'INTERNAL_SELF_MANAGED' for service attachments.
  load_balancing_scheme = local.is_google_apis_consumer ? "INTERNAL" : "INTERNAL_SELF_MANAGED"
  # The network to which this forwarding rule belongs.
  network = var.network
  # The subnetwork to which this forwarding rule belongs.
  subnetwork = var.subnetwork
  # The target service attachment URI or Google API bundle.
  target = var.target_service_attachment
  # The IP address for this forwarding rule. Uses an existing address or the one created by this module.
  ip_address = var.ip_address != null ? var.ip_address : one(google_compute_address.consumer[*].address)
  # Allows this PSC endpoint to be accessed from any region.
  allow_psc_global_access = var.allow_psc_global_access

  # Preconditions to ensure required variables are set.
  lifecycle {
    precondition {
      # Checks if required variables for consumer mode are set.
      condition     = var.project_id != null && var.name != null && var.region != null && var.network != null
      # Error message to display if the condition is not met.
      error_message = "When creating a consumer endpoint, 'project_id', 'name', 'region', and 'network' variables must be set."
    }
    precondition {
      # Checks if the target service attachment is provided.
      condition     = var.target_service_attachment != null
      # Error message to display if the condition is not met.
      error_message = "The 'target_service_attachment' variable must be set when psc_type is 'CONSUMER'."
    }
    precondition {
      # Checks if the consumer subnetwork is provided.
      condition     = var.subnetwork != null
      # Error message to display if the condition is not met.
      error_message = "The 'subnetwork' variable must be set when psc_type is 'CONSUMER'."
    }
  }
}
