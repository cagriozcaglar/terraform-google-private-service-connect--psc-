# Terraform Module for Google Cloud Private Service Connect

This module handles the creation of Google Cloud Private Service Connect (PSC) resources. It can operate in two distinct modes:

*   **Producer Mode (`psc_type = "producer"`)**: Creates a Service Attachment to publish a service, along with the necessary PSC NAT subnets. This allows consumers to connect to your service privately.
*   **Consumer Mode (`psc_type = "consumer"`)**: Creates a Forwarding Rule that acts as a PSC endpoint. This endpoint can connect to a producer's Service Attachment or to a managed Google API bundle (e.g., `all-apis`, `vpc-sc`).

The module is designed to be flexible, allowing for the creation of either side of a PSC connection with a single, unified interface.

## Usage

Below are examples of how to use this module for both producer and consumer scenarios.

### Producer: Creating a Service Attachment

This example creates a service attachment to publish an existing Internal Load Balancer. It requires a dedicated NAT subnet for PSC.

```hcl
module "psc_producer" {
  source = "./" // Or a path to your module registry

  name        = "my-producer-service"
  project_id  = "my-producer-project-id"
  region      = "us-central1"
  network     = "projects/my-producer-project-id/global/networks/my-producer-vpc"
  psc_type    = "producer"
  description = "Service attachment for my application"

  # The ILB forwarding rule to publish
  producer_target_service = "projects/my-producer-project-id/regions/us-central1/forwardingRules/my-ilb-forwarding-rule"
  
  # A list of dedicated subnets for PSC NAT
  producer_nat_subnets = ["10.10.0.0/24"]
  
  # Connection preference can be ACCEPT_AUTOMATIC or ACCEPT_MANUAL
  producer_connection_preference = "ACCEPT_MANUAL"

  # Optionally, pre-approve consumer projects
  producer_consumer_accept_lists = [
    {
      project_id_or_num = "my-consumer-project-id"
      connection_limit  = 5
    }
  ]
}
```

### Consumer: Creating a PSC Endpoint

This example creates a PSC endpoint (a forwarding rule) to connect to a published service. It reserves a new static internal IP address for the endpoint.

```hcl
module "psc_consumer" {
  source = "./" // Or a path to your module registry

  name        = "my-psc-endpoint"
  project_id  = "my-consumer-project-id"
  region      = "us-central1"
  network     = "projects/my-consumer-project-id/global/networks/my-consumer-vpc"
  psc_type    = "consumer"
  description = "Endpoint for connecting to my-producer-service"

  consumer_subnetwork = "projects/my-consumer-project-id/regions/us-central1/subnetworks/my-consumer-subnet"
  
  # Target can be a service attachment URI or a Google API bundle like "all-apis"
  consumer_target_service = module.psc_producer.service_attachment_uri

  # The module can create the IP address for you
  consumer_create_address = true
  
  # Optionally, specify a particular IP from the subnetwork
  consumer_ip_address = "10.20.0.100" 
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| consumer\_allow\_psc\_global\_access | Allow the PSC endpoint to be accessed from any region. If null, this is automatically set to true for Google API targets ('all-apis', 'vpc-sc'). | `bool` | `null` | no |
| consumer\_create\_address | If true, a new static internal IP address will be created for the consumer endpoint. | `bool` | `true` | no |
| consumer\_ip\_address | The IP address for the consumer endpoint. If `consumer_create_address` is true, this is the specific IP to reserve. If false, this must be the self-link of a pre-existing `google_compute_address` resource. | `string` | `null` | no |
| consumer\_subnetwork | The self-link of the subnetwork for the consumer endpoint. Required if psc\_type is 'consumer'. | `string` | `null` | yes |
| consumer\_target\_service | The URI of the target service attachment or a Google API bundle (e.g., 'all-apis', 'vpc-sc'). Required if psc\_type is 'consumer'. | `string` | `null` | yes |
| description | An optional description to apply to the created resources. | `string` | `null` | no |
| name | The base name for the Private Service Connect resources. | `string` | `null` | yes |
| network | The self-link of the VPC network where the PSC resources will be created. | `string` | `null` | yes |
| producer\_connection\_preference | The connection preference for the service attachment. Can be 'ACCEPT\_AUTOMATIC' or 'ACCEPT\_MANUAL'. | `string` | `"ACCEPT_AUTOMATIC"` | no |
| producer\_consumer\_accept\_lists | A list of consumer projects that are explicitly allowed to connect to the service attachment. | `list(object({ project_id_or_num = string, connection_limit = number }))` | `[]` | no |
| producer\_enable\_proxy\_protocol | If true, the PROXY protocol header is forwarded to the backend service. | `bool` | `false` | no |
| producer\_nat\_subnets | A list of CIDR ranges for the PSC NAT subnets to be created. Required if psc\_type is 'producer'. | `list(string)` | `[]` | yes |
| producer\_target\_service | The self-link of the Internal Load Balancer forwarding rule to be published. Required if psc\_type is 'producer'. | `string` | `null` | yes |
| project\_id | The project ID where the PSC resources will be created. | `string` | `null` | yes |
| psc\_type | The type of PSC component to create, either 'producer' (Service Attachment) or 'consumer' (Endpoint). If null, no resources are created. | `string` | `null` | yes |
| region | The GCP region for the PSC resources. | `string` | `null` | yes |

## Outputs

| Name | Description |
|------|-------------|
| consumer\_address | The created `google_compute_address` resource for the consumer endpoint. This is only available when `psc_type` is 'consumer' and `consumer_create_address` is true. |
| consumer\_endpoint\_ip\_address | The internal IP address of the consumer PSC endpoint. This is only available when `psc_type` is 'consumer'. |
| consumer\_forwarding\_rule | The created `google_compute_forwarding_rule` resource that acts as the PSC endpoint. This is only available when `psc_type` is 'consumer'. |
| nat\_subnets | A map of the created `google_compute_subnetwork` resources for PSC NAT. Keys are the CIDR ranges. This is only available when `psc_type` is 'producer'. |
| service\_attachment | The created `google_compute_service_attachment` resource. This is only available when `psc_type` is 'producer'. |
| service\_attachment\_uri | The URI of the created service attachment. Consumers will use this to connect. This is only available when `psc_type` is 'producer'. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

### Terraform Providers

The following providers are required by this module:

| Name | Version |
|------|---------|
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.54.0 |

### Google Cloud APIs

A project with the following APIs enabled is required:

*   `compute.googleapis.com`
