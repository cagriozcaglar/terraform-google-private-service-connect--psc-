variable "project_id" {
  description = "The project ID where the PSC resource will be created."
  type        = string
  default     = null
}

variable "region" {
  description = "The region where the PSC resource will be created."
  type        = string
  default     = null
}

variable "name" {
  description = "The name for the PSC resource (Service Attachment or Forwarding Rule)."
  type        = string
  default     = null
}

variable "create_producer_service_attachment" {
  description = "Set to true to create a producer-side Service Attachment. Mutually exclusive with `create_consumer_endpoint`."
  type        = bool
  default     = false
}

variable "create_consumer_endpoint" {
  description = "Set to true to create a consumer-side Forwarding Rule endpoint. Mutually exclusive with `create_producer_service_attachment`."
  type        = bool
  default     = false
}

variable "producer_network" {
  description = "The self-link of the VPC network for the producer's service attachment. Required if `create_producer_service_attachment` is true."
  type        = string
  default     = null
}

variable "target_service" {
  description = "The self-link of the forwarding rule of the Internal Load Balancer to be exposed. Required if `create_producer_service_attachment` is true."
  type        = string
  default     = null
}

variable "connection_preference" {
  description = "The connection preference for the service attachment. Can be `ACCEPT_AUTOMATIC` or `ACCEPT_MANUAL`."
  type        = string
  default     = "ACCEPT_AUTOMATIC"
  validation {
    condition     = contains(["ACCEPT_AUTOMATIC", "ACCEPT_MANUAL"], var.connection_preference)
    error_message = "The connection_preference must be either ACCEPT_AUTOMATIC or ACCEPT_MANUAL."
  }
}

variable "enable_proxy_protocol" {
  description = "If true, the PROXY protocol header will be sent to the backends. Only supported for TCP/SSL backends."
  type        = bool
  default     = false
}

variable "consumer_accept_list" {
  description = "A list of projects that are allowed to connect to the service attachment when `connection_preference` is `ACCEPT_MANUAL`."
  type = list(object({
    project_id_or_num = string
    connection_limit  = number
  }))
  default = []
}

variable "create_nat_subnet" {
  description = "If true, the module will create a new NAT subnet for the service attachment. If false, you must provide existing subnets via `nat_subnets_self_links`."
  type        = bool
  default     = true
}

variable "nat_subnet_name" {
  description = "The name of the NAT subnet to be created. Used only if `create_nat_subnet` is true."
  type        = string
  default     = null
}

variable "nat_subnet_cidr_range" {
  description = "The IP CIDR range for the NAT subnet to be created. Used only if `create_nat_subnet` is true."
  type        = string
  default     = null
}

variable "nat_subnets_self_links" {
  description = "A list of self-links of existing NAT subnets to use for the service attachment. Used only if `create_nat_subnet` is false."
  type        = list(string)
  default     = []
}

variable "consumer_network" {
  description = "The self-link of the VPC network where the consumer endpoint will be created. Required if `create_consumer_endpoint` is true."
  type        = string
  default     = null
}

variable "consumer_subnetwork" {
  description = "The self-link of the subnetwork where the consumer endpoint will be created. Required if `create_consumer_endpoint` is true."
  type        = string
  default     = null
}

variable "service_attachment_uri" {
  description = "The URI of the producer's service attachment to connect to. Required if `create_consumer_endpoint` is true."
  type        = string
  default     = null
}

variable "ip_address" {
  description = "The static internal IP address to assign to the consumer endpoint. If null, an ephemeral IP will be assigned. Used only if `create_consumer_endpoint` is true."
  type        = string
  default     = null
}
