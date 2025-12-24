# The base name for the Private Service Connect resources.
variable "name" {
  description = "The base name for the Private Service Connect resources."
  type        = string
  default     = null
}

# The project ID where the PSC resources will be created.
variable "project_id" {
  description = "The project ID where the PSC resources will be created."
  type        = string
  default     = null
}

# The GCP region for the PSC resources.
variable "region" {
  description = "The GCP region for the PSC resources."
  type        = string
  default     = null
}

# The self-link of the VPC network where the PSC resources will be created.
variable "network" {
  description = "The self-link of the VPC network where the PSC resources will be created."
  type        = string
  default     = null
}

# The type of PSC component to create, either 'producer' (Service Attachment) or 'consumer' (Endpoint). If null, no resources are created.
variable "psc_type" {
  description = "The type of PSC component to create, either 'producer' (Service Attachment) or 'consumer' (Endpoint). If null, no resources are created."
  type        = string
  default     = null
  validation {
    condition     = var.psc_type == null ? true : contains(["producer", "consumer"], var.psc_type)
    error_message = "The psc_type must be either 'producer', 'consumer' or null."
  }
}

# An optional description to apply to the created resources.
variable "description" {
  description = "An optional description to apply to the created resources."
  type        = string
  default     = null
}

# The self-link of the Internal Load Balancer forwarding rule to be published. Required if psc_type is 'producer'.
variable "producer_target_service" {
  description = "The self-link of the Internal Load Balancer forwarding rule to be published. Required if psc_type is 'producer'."
  type        = string
  default     = null
}

# The connection preference for the service attachment. Can be 'ACCEPT_AUTOMATIC' or 'ACCEPT_MANUAL'.
variable "producer_connection_preference" {
  description = "The connection preference for the service attachment. Can be 'ACCEPT_AUTOMATIC' or 'ACCEPT_MANUAL'."
  type        = string
  default     = "ACCEPT_AUTOMATIC"
}

# A list of CIDR ranges for the PSC NAT subnets to be created. Required if psc_type is 'producer'.
variable "producer_nat_subnets" {
  description = "A list of CIDR ranges for the PSC NAT subnets to be created. Required if psc_type is 'producer'."
  type        = list(string)
  default     = []
}

# If true, the PROXY protocol header is forwarded to the backend service.
variable "producer_enable_proxy_protocol" {
  description = "If true, the PROXY protocol header is forwarded to the backend service."
  type        = bool
  default     = false
}

# A list of consumer projects that are explicitly allowed to connect to the service attachment.
variable "producer_consumer_accept_lists" {
  description = "A list of consumer projects that are explicitly allowed to connect to the service attachment."
  type = list(object({
    project_id_or_num = string
    connection_limit  = number
  }))
  default = []
}

# The URI of the target service attachment or a Google API bundle (e.g., 'all-apis', 'vpc-sc'). Required if psc_type is 'consumer'.
variable "consumer_target_service" {
  description = "The URI of the target service attachment or a Google API bundle (e.g., 'all-apis', 'vpc-sc'). Required if psc_type is 'consumer'."
  type        = string
  default     = null
}

# The self-link of the subnetwork for the consumer endpoint. Required if psc_type is 'consumer'.
variable "consumer_subnetwork" {
  description = "The self-link of the subnetwork for the consumer endpoint. Required if psc_type is 'consumer'."
  type        = string
  default     = null
}

# The IP address for the consumer endpoint. If `consumer_create_address` is true, this is the specific IP to reserve. If false, this must be the self-link of a pre-existing `google_compute_address` resource.
variable "consumer_ip_address" {
  description = "The IP address for the consumer endpoint. If `consumer_create_address` is true, this is the specific IP to reserve. If false, this must be the self-link of a pre-existing `google_compute_address` resource."
  type        = string
  default     = null
}

# If true, a new static internal IP address will be created for the consumer endpoint.
variable "consumer_create_address" {
  description = "If true, a new static internal IP address will be created for the consumer endpoint."
  type        = bool
  default     = true
}

# Allow the PSC endpoint to be accessed from any region. If null, this is automatically set to true for Google API targets ('all-apis', 'vpc-sc').
variable "consumer_allow_psc_global_access" {
  description = "Allow the PSC endpoint to be accessed from any region. If null, this is automatically set to true for Google API targets ('all-apis', 'vpc-sc')."
  type        = bool
  default     = null
}
