# (Consumer-only) If true, the PSC endpoint can be accessed from any region. This is useful for endpoints connecting to Google APIs.
variable "allow_psc_global_access" {
  description = "(Consumer-only) If true, the PSC endpoint can be accessed from any region. This is useful for endpoints connecting to Google APIs."
  type        = bool
  default     = false
}

# (Producer-only) A list of projects that are allowed to connect to the service attachment.
variable "consumer_accept_lists" {
  description = "(Producer-only) A list of projects that are allowed to connect to the service attachment."
  type = list(object({
    project_id_or_num = string
    connection_limit  = number
  }))
  default = []
}

# (Producer-only) A list of projects that are not allowed to connect to the service attachment.
variable "consumer_reject_lists" {
  description = "(Producer-only) A list of projects that are not allowed to connect to the service attachment."
  type        = list(string)
  default     = []
}

# (Producer-only) The connection preference for the service attachment. Can be 'ACCEPT_AUTOMATIC' or 'ACCEPT_MANUAL'.
variable "connection_preference" {
  description = "(Producer-only) The connection preference for the service attachment. Can be 'ACCEPT_AUTOMATIC' or 'ACCEPT_MANUAL'."
  type        = string
  default     = "ACCEPT_AUTOMATIC"
  validation {
    condition     = contains(["ACCEPT_AUTOMATIC", "ACCEPT_MANUAL"], var.connection_preference)
    error_message = "The connection_preference must be either 'ACCEPT_AUTOMATIC' or 'ACCEPT_MANUAL'."
  }
}

# (Producer-only) Whether to create a dedicated NAT subnet for the service attachment. If false, existing subnets must be provided via `nat_subnets`.
variable "create_nat_subnet" {
  description = "(Producer-only) Whether to create a dedicated NAT subnet for the service attachment. If false, existing subnets must be provided via `nat_subnets`."
  type        = bool
  default     = true
}

# An optional description for the PSC resources.
variable "description" {
  description = "An optional description for the PSC resources."
  type        = string
  default     = null
}

# (Producer-only) If true, indicates that connections to the service attachment will be proxied and the source IP address of the consumer instance will be preserved.
variable "enable_proxy_protocol" {
  description = "(Producer-only) If true, indicates that connections to the service attachment will be proxied and the source IP address of the consumer instance will be preserved."
  type        = bool
  default     = true
}

# (Consumer-only) The self-link or IP address of a static internal IP address to use for the PSC endpoint. If not provided, a new one will be created.
variable "ip_address" {
  description = "(Consumer-only) The self-link or IP address of a static internal IP address to use for the PSC endpoint. If not provided, a new one will be created."
  type        = string
  default     = null
}

# The base name for the PSC resources.
variable "name" {
  description = "The base name for the PSC resources."
  type        = string
  default     = null
}

# (Producer-only) The IP CIDR range for the NAT subnet to be created. Required if `create_nat_subnet` is true.
variable "nat_subnet_ip_cidr_range" {
  description = "(Producer-only) The IP CIDR range for the NAT subnet to be created. Required if `create_nat_subnet` is true."
  type        = string
  default     = null
}

# (Producer-only) A list of self-links of existing NAT subnets to use for the service attachment. These are used in addition to the one created by the module if `create_nat_subnet` is true.
variable "nat_subnets" {
  description = "(Producer-only) A list of self-links of existing NAT subnets to use for the service attachment. These are used in addition to the one created by the module if `create_nat_subnet` is true."
  type        = list(string)
  default     = []
}

# The VPC network for the PSC resources. The network must be in the same project and region as the PSC resources.
variable "network" {
  description = "The VPC network for the PSC resources. The network must be in the same project and region as the PSC resources."
  type        = string
  default     = null
}

# The project ID where the PSC resources will be created.
variable "project_id" {
  description = "The project ID where the PSC resources will be created."
  type        = string
  default     = null
}

# The type of PSC setup to create. Must be one of 'PRODUCER' or 'CONSUMER'.
variable "psc_type" {
  description = "The type of PSC setup to create. Must be one of 'PRODUCER' or 'CONSUMER'."
  type        = string
  default     = null
  validation {
    condition     = var.psc_type == null ? true : contains(["PRODUCER", "CONSUMER"], var.psc_type)
    error_message = "The psc_type must be either 'PRODUCER' or 'CONSUMER'."
  }
}

# The region where the PSC resources will be created.
variable "region" {
  description = "The region where the PSC resources will be created."
  type        = string
  default     = null
}

# (Consumer-only) The self-link of the subnetwork where the PSC endpoint will be created.
variable "subnetwork" {
  description = "(Consumer-only) The self-link of the subnetwork where the PSC endpoint will be created."
  type        = string
  default     = null
}

# (Producer-only) The self-link of the forwarding rule of the internal load balancer to publish.
variable "target_service" {
  description = "(Producer-only) The self-link of the forwarding rule of the internal load balancer to publish."
  type        = string
  default     = null
}

# (Consumer-only) The self-link of the service attachment to connect to, or a Google-managed service bundle like 'all-apis' or 'vpc-sc'.
variable "target_service_attachment" {
  description = "(Consumer-only) The self-link of the service attachment to connect to, or a Google-managed service bundle like 'all-apis' or 'vpc-sc'."
  type        = string
  default     = null
}
