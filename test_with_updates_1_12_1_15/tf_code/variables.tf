# The variables.tf file is used to define the input variables of the module.
# These variables allow users to customize the behavior of the module without modifying the source code.
# Each variable is defined with a type, a description, and an optional default value.

variable "name" {
  description = "The base name for the Private Service Connect resources being created."
  type        = string
  default     = null
}

variable "project_id" {
  description = "The project ID where the PSC resources will be created."
  type        = string
  default     = null
}

variable "region" {
  description = "The region where the PSC resources will be created."
  type        = string
  default     = null
}

variable "network" {
  description = "The self-link of the VPC network where the PSC resources will be created."
  type        = string
  default     = null
}

variable "psc_type" {
  description = "The type of PSC configuration to create. Must be either 'PRODUCER' or 'CONSUMER'."
  type        = string
  default     = null
  validation {
    condition     = var.psc_type == null ? true : contains(["PRODUCER", "CONSUMER"], var.psc_type)
    error_message = "The psc_type must be either 'PRODUCER' or 'CONSUMER'."
  }
}

variable "description" {
  description = "An optional description to apply to the created PSC resources (service attachment or forwarding rule)."
  type        = string
  default     = "Private Service Connect resource."
}

# ------------------------------------------------------------------------------
# PRODUCER VARIABLES
# ------------------------------------------------------------------------------

variable "target_service" {
  description = "(Producer-only) The self-link of the internal load balancer's forwarding rule to be exposed by the service attachment."
  type        = string
  default     = null
}

variable "connection_preference" {
  description = "(Producer-only) The connection preference for the service attachment. 'ACCEPT_AUTOMATIC' accepts all connections. 'ACCEPT_MANUAL' requires connections to be explicitly approved."
  type        = string
  default     = "ACCEPT_AUTOMATIC"
  validation {
    condition     = contains(["ACCEPT_AUTOMATIC", "ACCEPT_MANUAL"], var.connection_preference)
    error_message = "The connection_preference must be either 'ACCEPT_AUTOMATIC' or 'ACCEPT_MANUAL'."
  }
}

variable "enable_proxy_protocol" {
  description = "(Producer-only) If true, the PROXY protocol header will be sent to backend instances."
  type        = bool
  default     = true
}

variable "create_psc_nat_subnet" {
  description = "(Producer-only) If true, a new subnet with purpose PRIVATE_SERVICE_CONNECT will be created. If false, you must provide existing subnets in 'psc_nat_subnets'."
  type        = bool
  default     = true
}

variable "psc_nat_subnet_cidr" {
  description = "(Producer-only) The CIDR range for the PSC NAT subnet to be created. Required if 'create_psc_nat_subnet' is true."
  type        = string
  default     = null
}

variable "psc_nat_subnets" {
  description = "(Producer-only) A list of self-links of existing subnets to use for PSC NAT. Required if 'create_psc_nat_subnet' is false."
  type        = list(string)
  default     = []
}

variable "consumer_accept_lists" {
  description = "(Producer-only) A list of consumer projects that are allowed to connect to the service attachment. Each object in the list should have 'project_id_or_num' and 'connection_limit'."
  type = list(object({
    project_id_or_num = string
    connection_limit  = number
  }))
  default = []
}

# ------------------------------------------------------------------------------
# CONSUMER VARIABLES
# ------------------------------------------------------------------------------

variable "target_service_attachment" {
  description = "(Consumer-only) The self-link of the service attachment to connect to. For Google APIs, use special values like 'all-apis' or 'vpc-sc'."
  type        = string
  default     = null
}

variable "create_psc_endpoint_ip" {
  description = "(Consumer-only) If true, a new static internal IP address will be created for the PSC endpoint. If false, provide an existing IP in 'psc_endpoint_ip_address'."
  type        = bool
  default     = true
}

variable "psc_endpoint_ip_address" {
  description = "(Consumer-only) An existing static internal IP address to use for the PSC endpoint. Required if 'create_psc_endpoint_ip' is false."
  type        = string
  default     = null
}

variable "psc_endpoint_subnet" {
  description = "(Consumer-only) The self-link of the subnet where the PSC endpoint and its IP address will be created."
  type        = string
  default     = null
}

variable "allow_global_access" {
  description = "(Consumer-only) If true, allows the PSC endpoint to be accessed from any region within the VPC. Useful for connecting to Google APIs."
  type        = bool
  default     = false
}

variable "consumer_load_balancing_scheme" {
  description = "(Consumer-only) The load balancing scheme for the consumer forwarding rule. Should be 'INTERNAL' for connecting to published services and null for connecting to Google APIs."
  type        = string
  default     = "INTERNAL"
}
