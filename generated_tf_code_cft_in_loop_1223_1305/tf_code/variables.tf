# This file defines the input variables for the module.

variable "connection_preference" {
  # The description of the variable.
  description = "The connection preference for the service attachment. Can be `ACCEPT_AUTOMATIC` or `ACCEPT_MANUAL`. Only applicable when psc_type is `producer`."
  # The type of the variable.
  type = string
  # The default value for the variable.
  default = "ACCEPT_AUTOMATIC"

  # Validation rules for the variable.
  validation {
    # The condition to be met for the variable value to be considered valid.
    condition     = contains(["ACCEPT_AUTOMATIC", "ACCEPT_MANUAL"], var.connection_preference)
    # The error message to display if the condition is not met.
    error_message = "The connection_preference must be either 'ACCEPT_AUTOMATIC' or 'ACCEPT_MANUAL'."
  }
}

variable "description" {
  # The description of the variable.
  description = "An optional description for the PSC resource."
  # The type of the variable.
  type = string
  # The default value for the variable.
  default = null
}

variable "enable_proxy_protocol" {
  # The description of the variable.
  description = "If true, enable the proxy protocol (version 1) to be used with this service attachment. Only applicable when psc_type is `producer`."
  # The type of the variable.
  type = bool
  # The default value for the variable.
  default = true
}

variable "global_access" {
  # The description of the variable.
  description = "Whether to allow PSC global access for Google APIs endpoint. Only applicable when psc_type is `google_apis`."
  # The type of the variable.
  type = bool
  # The default value for the variable.
  default = true
}

variable "google_apis_bundle" {
  # The description of the variable.
  description = "The Google APIs bundle to connect to. Must be `all-apis` or `vpc-sc`. Only applicable when psc_type is `google_apis`."
  # The type of the variable.
  type = string
  # The default value for the variable.
  default = "all-apis"

  # Validation rules for the variable.
  validation {
    # The condition to be met for the variable value to be considered valid.
    condition     = contains(["all-apis", "vpc-sc"], var.google_apis_bundle)
    # The error message to display if the condition is not met.
    error_message = "The google_apis_bundle must be either 'all-apis' or 'vpc-sc'."
  }
}

variable "name" {
  # The description of the variable.
  description = "The name for the PSC resource (endpoint or service attachment)."
  # The type of the variable.
  type = string
  # The default value for the variable.
  default = null
}

variable "network" {
  # The description of the variable.
  description = "The self-link of the VPC network for the PSC resource."
  # The type of the variable.
  type = string
  # The default value for the variable.
  default = null
}

variable "producer_ilb_forwarding_rule" {
  # The description of the variable.
  description = "The self-link of the Internal Load Balancer's forwarding rule to publish. Required when psc_type is `producer`."
  # The type of the variable.
  type = string
  # The default value for the variable.
  default = null
}

variable "project_id" {
  # The description of the variable.
  description = "The project ID where the PSC resource will be created."
  # The type of the variable.
  type = string
  # The default value for the variable.
  default = null
}

variable "psc_nat_subnet_cidr" {
  # The description of the variable.
  description = "The CIDR range for the PSC NAT subnet, which will be created automatically. Required when psc_type is `producer`."
  # The type of the variable.
  type = string
  # The default value for the variable.
  default = null
}

variable "psc_type" {
  # The description of the variable.
  description = "The type of PSC resource to create. Must be one of: `google_apis`, `consumer`, `producer`."
  # The type of the variable.
  type = string
  # The default value for the variable.
  default = null

  # Validation rules for the variable.
  validation {
    # The condition checks if psc_type is one of the allowed values. This is structured to avoid passing a null value to the contains function, which would cause an error.
    condition     = var.psc_type == null ? true : contains(["google_apis", "consumer", "producer"], var.psc_type)
    # The error message to display if the condition is not met.
    error_message = "The psc_type must be one of 'google_apis', 'consumer', 'producer'."
  }
}

variable "region" {
  # The description of the variable.
  description = "The region where the PSC resource will be created."
  # The type of the variable.
  type = string
  # The default value for the variable.
  default = null
}

variable "service_attachment_uri" {
  # The description of the variable.
  description = "The URI of the producer's service attachment to connect to. Required when psc_type is `consumer`."
  # The type of the variable.
  type = string
  # The default value for the variable.
  default = null
}

variable "subnetwork" {
  # The description of the variable.
  description = "The self-link of the subnetwork for the consumer endpoint's IP address. Required when psc_type is `google_apis` or `consumer`."
  # The type of the variable.
  type = string
  # The default value for the variable.
  default = null
}
