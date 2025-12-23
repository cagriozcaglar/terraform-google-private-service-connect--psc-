# /******************************************
# * Terraform-docs will be generated here
# *****************************************/
#
# # Module to create Private Service Connect (PSC) resources.
# This module supports three primary use cases, controlled by the `psc_type` variable:
# 1. PRODUCER: Creates a Service Attachment to publish a managed service.
# 2. CONSUMER_SERVICE: Creates a PSC endpoint (forwarding rule) to connect to a published third-party or internal service.
# 3. CONSUMER_GOOGLE_APIS: Creates a PSC endpoint (forwarding rule) for the `all-apis` bundle to privately access Google APIs.

locals {
  # Consolidate consumer forwarding rule resources into a single list for easier referencing in outputs.
  # This list will contain at most one element.
  consumer_forwarding_rules = concat(
    google_compute_forwarding_rule.consumer_service,
    google_compute_forwarding_rule.consumer_google_apis
  )
  # Consolidate producer service attachment resources into a single list for easier referencing in outputs.
  # This list will contain at most one element.
  producer_service_attachments = google_compute_service_attachment.producer

  # Consolidate all created resources into a single list. This is useful for generic outputs like id or self_link.
  # This list will contain at most one element.
  all_resources = concat(local.producer_service_attachments, local.consumer_forwarding_rules)
}

# Creates a PSC Service Attachment to publish a service from a producer VPC.
# This resource is only created when var.psc_type is "PRODUCER".
resource "google_compute_service_attachment" "producer" {
  # The number of instances to create. Creates the resource only if psc_type is PRODUCER.
  count = var.psc_type == "PRODUCER" ? 1 : 0

  # (Required) The project ID where the service attachment will be created.
  project = var.project_id
  # (Required) The region for the service attachment.
  region = var.region
  # (Required) The name for the PSC Service Attachment.
  name = var.name
  # (Optional) An optional description for the service attachment.
  description = var.description
  # (Required) The forwarding rule that serves as the target of this service attachment.
  target_service = var.target_service
  # (Required) A list of subnets from which to allocate IP addresses for this service attachment.
  nat_subnets = var.nat_subnets
  # (Optional) Specifies whether the proxy protocol header is enabled.
  enable_proxy_protocol = var.enable_proxy_protocol
  # (Required) The connection preference for the service attachment.
  # ACCEPT_AUTOMATIC: Automatically approve connections from consumers.
  # ACCEPT_MANUAL: Require manual approval for each connection.
  connection_preference = var.connection_preference
  # (Optional) If true, connections that are not explicitly accepted are rejected.
  reconcile_connections = var.reconcile_connections
  # (Optional) An array of projects that are not allowed to connect to this service attachment.
  consumer_reject_lists = var.consumer_reject_list

  # (Optional) An array of projects that are allowed to connect to this service attachment.
  dynamic "consumer_accept_lists" {
    # Iterates over the list of consumer projects to accept.
    for_each = var.consumer_accept_list
    content {
      # The project ID or number of the project to accept connections from.
      project_id_or_num = consumer_accept_lists.value.project_id_or_num
      # The number of consumer forwarding rules that can be successfully created from this project.
      connection_limit = consumer_accept_lists.value.connection_limit
    }
  }

  lifecycle {
    precondition {
      # Ensures that the name is provided for producer type.
      condition     = var.name != null
      error_message = "The 'name' variable must be set when psc_type is 'PRODUCER'."
    }
    precondition {
      # Ensures that the project_id is provided for producer type.
      condition     = var.project_id != null
      error_message = "The 'project_id' variable must be set when psc_type is 'PRODUCER'."
    }
    precondition {
      # Ensures that the region is provided for producer type.
      condition     = var.region != null
      error_message = "The 'region' variable must be set when psc_type is 'PRODUCER'."
    }
    precondition {
      # Ensures that the target_service is provided for producer type.
      condition     = var.target_service != null
      error_message = "The 'target_service' variable must be set when psc_type is 'PRODUCER'."
    }
    precondition {
      # Ensures that at least one NAT subnet is provided for producer type.
      condition     = length(var.nat_subnets) > 0
      error_message = "The 'nat_subnets' variable must contain at least one subnet when psc_type is 'PRODUCER'."
    }
  }
}

# Creates a PSC endpoint forwarding rule in a consumer VPC to connect to a published service.
# This resource is only created when var.psc_type is "CONSUMER_SERVICE".
resource "google_compute_forwarding_rule" "consumer_service" {
  # The number of instances to create. Creates the resource only if psc_type is CONSUMER_SERVICE.
  count = var.psc_type == "CONSUMER_SERVICE" ? 1 : 0

  # (Required) The project ID where the PSC endpoint will be created.
  project = var.project_id
  # (Required) The region for the PSC endpoint. Must match the producer's service attachment region.
  region = var.region
  # (Required) The name for the PSC endpoint forwarding rule.
  name = var.name
  # (Optional) An optional description for the PSC endpoint.
  description = var.description
  # (Required) The self-link of the consumer's VPC network.
  network = var.network
  # (Required) The self-link of the subnetwork where the endpoint's IP address will be allocated.
  subnetwork = var.subnetwork
  # (Optional) An optional static internal IP address for the PSC endpoint. If not provided, an ephemeral address is allocated.
  ip_address = var.ip_address
  # (Required) The resource URI of the producer's service attachment.
  target = var.target_service_attachment
  # (Required) For this PSC type, the load balancing scheme must be INTERNAL.
  load_balancing_scheme = "INTERNAL"
  # (Optional) If true, allows the PSC endpoint to be accessed from all regions.
  allow_psc_global_access = var.allow_psc_global_access

  lifecycle {
    precondition {
      # Ensures that the name is provided for consumer service type.
      condition     = var.name != null
      error_message = "The 'name' variable must be set when psc_type is 'CONSUMER_SERVICE'."
    }
    precondition {
      # Ensures that the project_id is provided for consumer service type.
      condition     = var.project_id != null
      error_message = "The 'project_id' variable must be set when psc_type is 'CONSUMER_SERVICE'."
    }
    precondition {
      # Ensures that the region is provided for consumer service type.
      condition     = var.region != null
      error_message = "The 'region' variable must be set when psc_type is 'CONSUMER_SERVICE'."
    }
    precondition {
      # Ensures that the network is provided for consumer service type.
      condition     = var.network != null
      error_message = "The 'network' variable must be set when psc_type is 'CONSUMER_SERVICE'."
    }
    precondition {
      # Ensures that the subnetwork is provided for consumer service type.
      condition     = var.subnetwork != null
      error_message = "The 'subnetwork' variable must be set when psc_type is 'CONSUMER_SERVICE'."
    }
    precondition {
      # Ensures that the target service attachment is provided for consumer service type.
      condition     = var.target_service_attachment != null
      error_message = "The 'target_service_attachment' variable must be set when psc_type is 'CONSUMER_SERVICE'."
    }
  }
}

# Creates a PSC endpoint for the "all-apis" bundle, allowing private access to Google APIs from within a VPC.
# This resource is only created when var.psc_type is "CONSUMER_GOOGLE_APIS".
resource "google_compute_forwarding_rule" "consumer_google_apis" {
  # The number of instances to create. Creates the resource only if psc_type is CONSUMER_GOOGLE_APIS.
  count = var.psc_type == "CONSUMER_GOOGLE_APIS" ? 1 : 0

  # (Required) The project ID where the Google APIs endpoint will be created.
  project = var.project_id
  # (Required) The region for the PSC endpoint.
  region = var.region
  # (Required) The name for the 'all-apis' PSC endpoint forwarding rule.
  name = var.name
  # (Optional) An optional description for the Google APIs endpoint.
  description = var.description
  # (Required) The self-link of the VPC network that needs private API access.
  network = var.network
  # (Required) The self-link of the subnetwork where the endpoint's IP address will be allocated.
  subnetwork = var.subnetwork
  # (Optional) An optional static internal IP address for the PSC endpoint. If not provided, an ephemeral address is allocated.
  ip_address = var.ip_address
  # (Required) For the "all-apis" bundle, the target is the special string "all-apis".
  target = "all-apis"
  # (Required) For the "all-apis" bundle, the load balancing scheme must be INTERNAL_MANAGED.
  load_balancing_scheme = "INTERNAL_MANAGED"

  lifecycle {
    precondition {
      # Ensures that the name is provided for consumer Google APIs type.
      condition     = var.name != null
      error_message = "The 'name' variable must be set when psc_type is 'CONSUMER_GOOGLE_APIS'."
    }
    precondition {
      # Ensures that the project_id is provided for consumer Google APIs type.
      condition     = var.project_id != null
      error_message = "The 'project_id' variable must be set when psc_type is 'CONSUMER_GOOGLE_APIS'."
    }
    precondition {
      # Ensures that the region is provided for consumer Google APIs type.
      condition     = var.region != null
      error_message = "The 'region' variable must be set when psc_type is 'CONSUMER_GOOGLE_APIS'."
    }
    precondition {
      # Ensures that the network is provided for consumer Google APIs type.
      condition     = var.network != null
      error_message = "The 'network' variable must be set when psc_type is 'CONSUMER_GOOGLE_APIS'."
    }
    precondition {
      # Ensures that the subnetwork is provided for consumer Google APIs type.
      condition     = var.subnetwork != null
      error_message = "The 'subnetwork' variable must be set when psc_type is 'CONSUMER_GOOGLE_APIS'."
    }
  }
}
