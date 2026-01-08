# This module handles the creation of Google Cloud Private Service Connect (PSC) resources.
# It can operate in three distinct modes:
#
# 1. Producer Mode: Creates a Service Attachment to publish a service (an Internal Load Balancer).
#    This requires creating one or more dedicated PSC NAT subnets.
#    To use this mode, provide the `target_service` variable.
#
# 2. Consumer Service Mode: Creates a forwarding rule (PSC endpoint) to connect to a published third-party or internal service.
#    This requires the producer's Service Attachment URI.
#    To use this mode, provide the `target_service_attachment` variable.
#
# 3. Consumer Google APIs Mode: Creates a global forwarding rule (PSC endpoint) to connect privately to Google APIs.
#    To use this mode, provide the `google_apis_bundle` variable (e.g., "all-apis").
#
# The module enforces that exactly one of these modes can be active at a time.
#
# Integration tests for this module are located in the `test/integration` directory.
# They are implemented using the blueprint-test framework.

# <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
# <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

locals {
  # Determine the operating mode based on which primary variable is set.
  is_producer_mode             = var.target_service != null
  is_consumer_service_mode     = var.target_service_attachment != null
  is_consumer_google_apis_mode = var.google_apis_bundle != null
}

# This resource enforces the module's contract, ensuring that it is configured correctly
# for one of the three supported modes. It is only created if one of the modes is active.
resource "null_resource" "validation" {
  # Create this validation resource only if at least one mode is selected.
  count = anytrue([
    local.is_producer_mode,
    local.is_consumer_service_mode,
    local.is_consumer_google_apis_mode
  ]) ? 1 : 0

  # Use triggers to ensure preconditions are checked on every plan.
  triggers = {
    mode_check = join("-", [
      local.is_producer_mode,
      local.is_consumer_service_mode,
      local.is_consumer_google_apis_mode
    ])
  }

  lifecycle {
    # Precondition to ensure exactly one mode is selected.
    precondition {
      condition     = (local.is_producer_mode ? 1 : 0) + (local.is_consumer_service_mode ? 1 : 0) + (local.is_consumer_google_apis_mode ? 1 : 0) == 1
      error_message = "Exactly one of 'target_service', 'target_service_attachment', or 'google_apis_bundle' must be specified to determine the module's operation mode."
    }

    # Precondition to ensure required variables are set.
    precondition {
      condition     = var.project_id != null
      error_message = "The 'project_id' variable must be provided."
    }
    precondition {
      condition     = var.name != null
      error_message = "The 'name' variable must be provided."
    }
    precondition {
      condition     = var.network != null
      error_message = "The 'network' variable must be provided."
    }

    # Preconditions for producer mode.
    precondition {
      condition     = !local.is_producer_mode || length(var.psc_nat_subnets) > 0
      error_message = "When in producer mode (target_service is set), at least one CIDR range must be provided in 'psc_nat_subnets'."
    }
    precondition {
      condition     = !local.is_producer_mode || var.region != null
      error_message = "When in producer mode (target_service is set), 'region' must be specified."
    }

    # Preconditions for consumer service mode.
    precondition {
      condition     = !local.is_consumer_service_mode || var.subnetwork != null
      error_message = "When in consumer service mode (target_service_attachment is set), 'subnetwork' must be specified."
    }
    precondition {
      condition     = !local.is_consumer_service_mode || var.region != null
      error_message = "When in consumer service mode (target_service_attachment is set), 'region' must be specified."
    }

    # Precondition for consumer Google APIs mode.
    precondition {
      condition     = !local.is_consumer_google_apis_mode || var.global_address_ip != null
      error_message = "When in Google APIs mode (google_apis_bundle is set), 'global_address_ip' must be specified."
    }
  }
}

#
# Producer Mode Resources
#

# Creates one or more dedicated subnets for PSC Network Address Translation (NAT).
# This is a prerequisite for creating a Service Attachment.
resource "google_compute_subnetwork" "psc_nat_subnets" {
  # Create NAT subnets only in producer mode.
  for_each = local.is_producer_mode ? toset(var.psc_nat_subnets) : []

  # The project ID where the subnetwork will be created.
  project = var.project_id
  # A unique name for the PSC NAT subnetwork, derived from the base name and CIDR.
  name = format("%s-nat-%s", var.name, replace(each.value, "/[^0-9]/", ""))
  # The region for the subnetwork, must match the service attachment.
  region = var.region
  # The VPC network to which this subnetwork belongs.
  network = var.network
  # The IP address range of the subnetwork in CIDR format.
  ip_cidr_range = each.value
  # This purpose is required for subnets used by Private Service Connect.
  purpose = "PRIVATE_SERVICE_CONNECT"
}

# The Service Attachment publishes a service (an ILB forwarding rule) for consumption by other VPCs.
resource "google_compute_service_attachment" "producer_service" {
  # Create a service attachment only in producer mode.
  count = local.is_producer_mode ? 1 : 0

  # The project ID where the service attachment will be created.
  project = var.project_id
  # A unique name for the service attachment.
  name = var.name
  # The region for the service attachment.
  region = var.region
  # An optional description of this resource.
  description = var.description
  # Specifies if the proxy protocol must be used when sending traffic to the target service.
  enable_proxy_protocol = var.enable_proxy_protocol
  # The connection preference for this service attachment.
  connection_preference = var.connection_preference
  # The list of PSC NAT subnets to use for this service attachment.
  nat_subnets = values(google_compute_subnetwork.psc_nat_subnets)[*].self_link
  # The forwarding rule of the internal load balancer to publish.
  target_service = var.target_service
  # If true, connections from the same project will be automatically accepted.
  reconcile_connections = var.reconcile_connections

  # A list of projects that are allowed to connect to this service attachment.
  dynamic "consumer_accept_lists" {
    for_each = var.consumer_accept_list
    iterator = consumer
    content {
      # The project ID or number which is allowed to connect.
      project_id_or_num = consumer.value.project_id_or_num
      # The number of connections for this project.
      connection_limit = consumer.value.connection_limit
    }
  }
}

#
# Consumer Service Mode Resources
#

# Reserves a static internal IP address for the PSC endpoint.
# This is created only if an existing IP address is not provided via `var.ip_address`.
resource "google_compute_address" "psc_endpoint_ip" {
  # Create a new IP address only if in consumer service mode and no existing IP is provided.
  count = local.is_consumer_service_mode && var.ip_address == null ? 1 : 0

  # The project ID where the address will be created.
  project = var.project_id
  # The name of the address resource.
  name = format("%s-ip", var.name)
  # The region for this address.
  region = var.region
  # The subnetwork that this address will belong to.
  subnetwork = var.subnetwork
  # The type of this address. Must be INTERNAL for PSC.
  address_type = "INTERNAL"
  # An optional description of this resource.
  description = "Reserved static internal IP for PSC endpoint '${var.name}'"
}

# The Forwarding Rule acts as the PSC endpoint, directing traffic to the producer's service.
resource "google_compute_forwarding_rule" "psc_endpoint" {
  # Create a forwarding rule only in consumer service mode.
  count = local.is_consumer_service_mode ? 1 : 0

  # The project ID where the forwarding rule will be created.
  project = var.project_id
  # A unique name for the forwarding rule.
  name = var.name
  # The region for this forwarding rule.
  region = var.region
  # The network that this forwarding rule belongs to.
  network = var.network
  # The IP address that this forwarding rule is serving on.
  ip_address = var.ip_address == null ? google_compute_address.psc_endpoint_ip[0].address : var.ip_address
  # The Service Attachment URI of the producer's service.
  target = var.target_service_attachment
  # An optional description of this resource.
  description = var.description
  # This field must be empty for PSC forwarding rules.
  load_balancing_scheme = ""

  # This allows the forwarding rule to be recreated without causing downtime, if possible.
  lifecycle {
    create_before_destroy = true
  }
}

#
# Consumer Google APIs Mode Resources
#

# Creates a global internal IP address with the specific purpose required for PSC access to Google APIs.
resource "google_compute_global_address" "private_google_access_ip" {
  # Create a global address only in Google APIs mode.
  count = local.is_consumer_google_apis_mode ? 1 : 0

  # The project ID where the global address will be created.
  project = var.project_id
  # A unique name for the global address.
  name = var.name
  # The purpose of this address, required for PSC to Google APIs.
  purpose = "PRIVATE_SERVICE_CONNECT"
  # The type of this address.
  address_type = "INTERNAL"
  # The static IP address to reserve.
  address = var.global_address_ip
  # The network that this address belongs to.
  network = var.network
  # An optional description of this resource.
  description = "Global IP for PSC endpoint to Google APIs"
}

# The global Forwarding Rule acts as the PSC endpoint for accessing Google APIs.
resource "google_compute_forwarding_rule" "psc_google_apis_endpoint" {
  # Create a global forwarding rule only in Google APIs mode.
  count = local.is_consumer_google_apis_mode ? 1 : 0

  # The project ID where the forwarding rule will be created.
  project = var.project_id
  # A unique name for the forwarding rule.
  name = var.name
  # The network that this forwarding rule belongs to.
  network = var.network
  # The IP address that this forwarding rule is serving on.
  ip_address = google_compute_global_address.private_google_access_ip[0].address
  # The target for the forwarding rule. For Google APIs, this is a pre-defined bundle.
  target = var.google_apis_bundle
  # This field is not used for PSC and should be empty.
  load_balancing_scheme = ""
  # An optional description of this resource.
  description = var.description

  # This allows the forwarding rule to be recreated without causing downtime, if possible.
  lifecycle {
    create_before_destroy = true
  }
}
