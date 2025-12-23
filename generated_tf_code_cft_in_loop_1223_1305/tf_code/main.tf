# This file contains the main Terraform logic for creating Private Service Connect resources.

# locals block to define local variables for conditional logic.
locals {
  # is_google_apis_endpoint is a boolean to control resource creation when psc_type is 'google_apis'.
  is_google_apis_endpoint = var.psc_type == "google_apis"
  # is_consumer_endpoint is a boolean to control resource creation when psc_type is 'consumer'.
  is_consumer_endpoint = var.psc_type == "consumer"
  # is_producer_attachment is a boolean to control resource creation when psc_type is 'producer'.
  is_producer_attachment = var.psc_type == "producer"

  # is_endpoint is a general boolean for any type of consumer-side endpoint.
  is_endpoint = local.is_google_apis_endpoint || local.is_consumer_endpoint

  # endpoint_target determines the target for the forwarding rule based on the psc_type.
  # For Google APIs, this is the bundle name (e.g., 'all-apis' or 'vpc-sc'). For other services, it's the service attachment URI.
  endpoint_target = local.is_google_apis_endpoint ? var.google_apis_bundle : var.service_attachment_uri

  # load_balancing_scheme determines the load balancing scheme for the forwarding rule.
  # It must be null (omitted) for PSC to Google APIs and INTERNAL for other PSC connections.
  load_balancing_scheme = local.is_google_apis_endpoint ? null : "INTERNAL"
}

# This resource reserves a static internal IP address for the PSC endpoint.
resource "google_compute_address" "endpoint_ip" {
  # Create this resource only if creating a consumer-side endpoint.
  count = local.is_endpoint ? 1 : 0

  # The project ID where the address will be created.
  project = var.project_id
  # The name of the address resource.
  name = "${var.name}-ip"
  # The subnetwork that this address will be allocated from.
  subnetwork = var.subnetwork
  # The type of address to reserve, which must be INTERNAL for PSC.
  address_type = "INTERNAL"
  # The region where the address will be created.
  region = var.region

  # The lifecycle block provides meta-arguments for the resource.
  lifecycle {
    # The precondition block defines a condition that must be met before the resource can be created.
    precondition {
      # The condition to evaluate.
      condition     = var.project_id != null && var.name != null && var.subnetwork != null && var.region != null
      # The error message to display if the condition is false.
      error_message = "When creating a PSC endpoint, 'project_id', 'name', 'region', and 'subnetwork' must be specified."
    }
  }
}

# This resource creates the PSC forwarding rule that acts as the endpoint.
resource "google_compute_forwarding_rule" "psc_endpoint" {
  # Create this resource only if creating a consumer-side endpoint.
  count = local.is_endpoint ? 1 : 0

  # The project ID where the forwarding rule will be created.
  project = var.project_id
  # The name of the forwarding rule.
  name = var.name
  # The region where the forwarding rule will be created.
  region = var.region
  # The self-link of the VPC network this forwarding rule belongs to.
  network = var.network
  # The self-link of the reserved internal IP address for the endpoint.
  ip_address = google_compute_address.endpoint_ip[0].self_link
  # The target of the forwarding rule, either a Google APIs bundle or a service attachment URI.
  target = local.endpoint_target
  # The load balancing scheme, which differs for Google APIs vs. other services.
  load_balancing_scheme = local.load_balancing_scheme
  # An optional description for the forwarding rule.
  description = var.description
  # This flag is only applicable for PSC connections to Google APIs. Setting it to null for other types ensures it's omitted from the API call.
  allow_psc_global_access = local.is_google_apis_endpoint ? var.global_access : null

  # The lifecycle block provides meta-arguments for the resource.
  lifecycle {
    # The precondition block defines a condition that must be met before the resource can be created.
    precondition {
      # The condition to evaluate.
      condition     = var.project_id != null && var.name != null && var.region != null && var.network != null && var.subnetwork != null
      # The error message to display if the condition is false.
      error_message = "When creating a PSC endpoint, 'project_id', 'name', 'region', 'network', and 'subnetwork' must be specified."
    }
    # The precondition block defines a condition that must be met before the resource can be created.
    precondition {
      # The condition to evaluate.
      condition     = !local.is_consumer_endpoint || var.service_attachment_uri != null
      # The error message to display if the condition is false.
      error_message = "The 'service_attachment_uri' variable must be set when psc_type is 'consumer'."
    }
  }
}

# This resource creates a dedicated subnet for PSC NAT functionality, which is required when publishing a service.
resource "google_compute_subnetwork" "psc_nat_subnet" {
  # Create this resource only if creating a producer-side service attachment.
  count = local.is_producer_attachment ? 1 : 0

  # The project ID where the subnetwork will be created.
  project = var.project_id
  # The name of the PSC NAT subnetwork.
  name = "${var.name}-psc-nat"
  # The IP address range of the subnetwork in CIDR format.
  ip_cidr_range = var.psc_nat_subnet_cidr
  # The region where the subnetwork will be created.
  region = var.region
  # The self-link of the network to which this subnetwork belongs.
  network = var.network
  # The purpose of the subnetwork, which must be PRIVATE_SERVICE_CONNECT.
  purpose = "PRIVATE_SERVICE_CONNECT"

  # The lifecycle block provides meta-arguments for the resource.
  lifecycle {
    # The precondition block defines a condition that must be met before the resource can be created.
    precondition {
      # The condition to evaluate.
      condition     = var.project_id != null && var.name != null && var.psc_nat_subnet_cidr != null && var.region != null && var.network != null
      # The error message to display if the condition is false.
      error_message = "When creating a PSC NAT subnet, 'project_id', 'name', 'region', 'network', and 'psc_nat_subnet_cidr' must be specified."
    }
  }
}

# This resource creates the service attachment to publish the service fronted by an ILB.
resource "google_compute_service_attachment" "producer_service" {
  # Create this resource only if creating a producer-side service attachment.
  count = local.is_producer_attachment ? 1 : 0

  # The project ID where the service attachment will be created.
  project = var.project_id
  # The name of the service attachment.
  name = var.name
  # The region where the service attachment will be created.
  region = var.region
  # An optional description for the service attachment.
  description = var.description
  # Specifies whether to enable the proxy protocol.
  enable_proxy_protocol = var.enable_proxy_protocol
  # The connection preference for consumers connecting to the service.
  connection_preference = var.connection_preference
  # A list of self-links of PSC NAT subnetworks to use for this service attachment.
  nat_subnets = [google_compute_subnetwork.psc_nat_subnet[0].self_link]
  # The self-link of the ILB forwarding rule that this service attachment will publish.
  target_service = var.producer_ilb_forwarding_rule
  # If true, connections from consumers whose projects are not in the accept list will be automatically rejected.
  reconcile_connections = true

  # The lifecycle block provides meta-arguments for the resource.
  lifecycle {
    # The precondition block defines a condition that must be met before the resource can be created.
    precondition {
      # The condition to evaluate.
      condition     = var.project_id != null && var.name != null && var.region != null && var.producer_ilb_forwarding_rule != null && var.psc_nat_subnet_cidr != null
      # The error message to display if the condition is false.
      error_message = "When creating a service attachment, 'project_id', 'name', 'region', 'producer_ilb_forwarding_rule', and 'psc_nat_subnet_cidr' must be specified."
    }
  }
}
