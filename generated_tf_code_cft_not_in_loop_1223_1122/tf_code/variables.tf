variable "allow_psc_global_access" {
  # The description for the allow_psc_global_access variable.
  description = "CONSUMER_SERVICE only. If true, allows the PSC endpoint to be accessed from all regions."
  # The type of the variable.
  type        = bool
  # The default value for the variable.
  default     = false
}

variable "connection_preference" {
  # The description for the connection_preference variable.
  description = "PRODUCER only. The connection preference for the service attachment. Valid values are 'ACCEPT_AUTOMATIC' or 'ACCEPT_MANUAL'."
  # The type of the variable.
  type        = string
  # The default value for the variable.
  default     = "ACCEPT_MANUAL"

  validation {
    # The validation condition.
    condition     = contains(["ACCEPT_AUTOMATIC", "ACCEPT_MANUAL"], var.connection_preference)
    # The error message to display if validation fails.
    error_message = "The connection_preference must be either 'ACCEPT_AUTOMATIC' or 'ACCEPT_MANUAL'."
  }
}

variable "consumer_accept_list" {
  # The description for the consumer_accept_list variable.
  description = "PRODUCER only. A list of projects that are allowed to connect to this service attachment."
  # The type of the variable, a list of objects with project and connection limit.
  type = list(object({
    project_id_or_num = string
    connection_limit  = number
  }))
  # The default value for the variable.
  default = []
}

variable "consumer_reject_list" {
  # The description for the consumer_reject_list variable.
  description = "PRODUCER only. A list of project IDs or numbers that are not allowed to connect to this service attachment."
  # The type of the variable.
  type        = list(string)
  # The default value for the variable.
  default     = []
}

variable "description" {
  # The description for the description variable.
  description = "An optional description for the PSC resource."
  # The type of the variable.
  type        = string
  # The default value for the variable.
  default     = null
}

variable "enable_proxy_protocol" {
  # The description for the enable_proxy_protocol variable.
  description = "PRODUCER only. If true, the PROXY protocol header is enabled."
  # The type of the variable.
  type        = bool
  # The default value for the variable.
  default     = false
}

variable "ip_address" {
  # The description for the ip_address variable.
  description = "CONSUMER only. An optional static internal IP address for the PSC endpoint. If not provided, an ephemeral address from the subnetwork is allocated."
  # The type of the variable.
  type        = string
  # The default value for the variable.
  default     = null
}

variable "name" {
  # The description for the name variable.
  description = "The name for the Private Service Connect resource (Service Attachment or Forwarding Rule). Required when `psc_type` is not null."
  # The type of the variable.
  type        = string
  # The default value for the variable.
  default     = null
}

variable "nat_subnets" {
  # The description for the nat_subnets variable.
  description = "PRODUCER only. A list of self-links for the PSC NAT subnets. These subnets are used to source NAT traffic from consumers."
  # The type of the variable.
  type        = list(string)
  # The default value for the variable.
  default     = []
}

variable "network" {
  # The description for the network variable.
  description = "CONSUMER only. The self-link of the consumer's VPC network where the PSC endpoint will be created."
  # The type of the variable.
  type        = string
  # The default value for the variable.
  default     = null
}

variable "project_id" {
  # The description for the project_id variable.
  description = "The project ID where the Private Service Connect resource will be created. Required when `psc_type` is not null."
  # The type of the variable.
  type        = string
  # The default value for the variable.
  default     = null
}

variable "psc_type" {
  # The description for the psc_type variable.
  description = "The type of PSC resource to create. If null, no resource will be created. Must be one of: 'PRODUCER', 'CONSUMER_SERVICE', 'CONSUMER_GOOGLE_APIS'."
  # The type of the variable.
  type        = string
  # The default value for the variable. If null, no resource is created.
  default     = null

  validation {
    # The validation condition.
    condition     = var.psc_type == null ? true : contains(["PRODUCER", "CONSUMER_SERVICE", "CONSUMER_GOOGLE_APIS"], var.psc_type)
    # The error message to display if validation fails.
    error_message = "If set, the psc_type must be one of 'PRODUCER', 'CONSUMER_SERVICE', or 'CONSUMER_GOOGLE_APIS'."
  }
}

variable "reconcile_connections" {
  # The description for the reconcile_connections variable.
  description = "PRODUCER only. If true, connections that are not explicitly accepted are rejected."
  # The type of the variable.
  type        = bool
  # The default value for the variable.
  default     = true
}

variable "region" {
  # The description for the region variable.
  description = "The region where the Private Service Connect resource will be created. Required when `psc_type` is not null."
  # The type of the variable.
  type        = string
  # The default value for the variable.
  default     = null
}

variable "subnetwork" {
  # The description for the subnetwork variable.
  description = "CONSUMER only. The self-link of the subnetwork where the endpoint's IP address will be allocated."
  # The type of the variable.
  type        = string
  # The default value for the variable.
  default     = null
}

variable "target_service" {
  # The description for the target_service variable.
  description = "PRODUCER only. The full self-link or ID of the internal load balancer's forwarding rule that fronts the service."
  # The type of the variable.
  type        = string
  # The default value for the variable.
  default     = null
}

variable "target_service_attachment" {
  # The description for the target_service_attachment variable.
  description = "CONSUMER_SERVICE only. The full resource URI of the producer's service attachment to connect to."
  # The type of the variable.
  type        = string
  # The default value for the variable.
  default     = null
}
