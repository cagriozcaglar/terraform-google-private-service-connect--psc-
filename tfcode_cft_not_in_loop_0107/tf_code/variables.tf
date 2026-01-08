variable "project_id" {
  description = "The project ID where the PSC resources will be created."
  type        = string
  default     = null
}

variable "name" {
  description = "The base name for the PSC resources being created."
  type        = string
  default     = null
}

variable "region" {
  description = "The region for the PSC resources. Not used for the 'Google APIs' mode, which creates global resources."
  type        = string
  default     = null
}

variable "network" {
  description = "The self-link of the VPC network where the PSC resources will be created."
  type        = string
  default     = null
}

variable "description" {
  description = "An optional description to apply to the created PSC resources."
  type        = string
  default     = "Private Service Connect resource managed by Terraform"
}

variable "target_service" {
  description = "PRODUCER MODE: The self-link of the Internal Load Balancer's forwarding rule to be published. Setting this variable activates producer mode."
  type        = string
  default     = null
}

variable "psc_nat_subnets" {
  description = "PRODUCER MODE: A list of CIDR ranges for the PSC NAT subnets to be created. These subnets are used for the service attachment."
  type        = list(string)
  default     = []
}

variable "connection_preference" {
  description = "PRODUCER MODE: The connection preference for the service attachment. Can be ACCEPT_AUTOMATIC or ACCEPT_MANUAL."
  type        = string
  default     = "ACCEPT_MANUAL"
  validation {
    condition     = contains(["ACCEPT_AUTOMATIC", "ACCEPT_MANUAL"], var.connection_preference)
    error_message = "The connection_preference must be either 'ACCEPT_AUTOMATIC' or 'ACCEPT_MANUAL'."
  }
}

variable "enable_proxy_protocol" {
  description = "PRODUCER MODE: If true, the PROXY protocol header will be sent to the backend service."
  type        = bool
  default     = false
}

variable "reconcile_connections" {
  description = "PRODUCER MODE: If true, connections from consumers in the same project are automatically accepted."
  type        = bool
  default     = true
}

variable "consumer_accept_list" {
  description = "PRODUCER MODE: A list of projects that are allowed to connect to this service attachment."
  type = list(object({
    project_id_or_num = string
    connection_limit  = number
  }))
  default = []
}

variable "target_service_attachment" {
  description = "CONSUMER SERVICE MODE: The URI of the producer's Service Attachment to connect to. Setting this variable activates consumer service mode."
  type        = string
  default     = null
}

variable "subnetwork" {
  description = "CONSUMER SERVICE MODE: The self-link of the subnetwork where the PSC endpoint's IP will be allocated."
  type        = string
  default     = null
}

variable "ip_address" {
  description = "CONSUMER SERVICE MODE: A reserved static internal IP address to use for the PSC endpoint. If not provided, a new one will be created."
  type        = string
  default     = null
}

variable "google_apis_bundle" {
  description = "CONSUMER GOOGLE APIS MODE: The target Google APIs bundle to connect to (e.g., 'all-apis' or 'vpc-sc'). Setting this variable activates consumer Google APIs mode."
  type        = string
  default     = null
}

variable "global_address_ip" {
  description = "CONSUMER GOOGLE APIS MODE: The specific IP address to reserve for the global PSC endpoint. This must be a valid IP address."
  type        = string
  default     = null
}
