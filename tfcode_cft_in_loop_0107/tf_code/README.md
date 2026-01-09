# Google Cloud Private Service Connect (PSC) Terraform Module

This module simplifies the creation of Google Cloud Private Service Connect (PSC) resources. It operates in two distinct modes, controlled by the `psc_type` variable:
-   **`PRODUCER`**: Creates a Service Attachment to publish a service, making it available for consumption. This mode can also create the required PSC NAT subnet automatically.
-   **`CONSUMER`**: Creates an Endpoint (as a forwarding rule) to privately consume a published service or access Google APIs within your VPC.

## Prerequisites

Before you use this module, ensure the following APIs are enabled on the project(s) you are using:

-   Compute Engine API: `compute.googleapis.com`

You can enable the API by running the following command:

```bash
gcloud services enable compute.googleapis.com --project <your-project-id>
```

## Usage

Below are examples of how to use this module for both producer and consumer scenarios.

### Producer (Service Attachment) Example

This example creates a service attachment to publish an existing internal load balancer. It also automatically creates the necessary NAT subnet for PSC.

```terraform
module "psc_producer" {
  source = "./" // Or your module source

  psc_type                 = "PRODUCER"
  project_id               = "your-producer-project-id"
  region                   = "us-central1"
  name                     = "my-psc-service"
  description              = "Service Attachment for my-app"
  network                  = "projects/your-producer-project-id/global/networks/your-vpc"
  target_service           = "projects/your-producer-project-id/regions/us-central1/forwardingRules/my-ilb-forwarding-rule"
  create_nat_subnet        = true
  nat_subnet_ip_cidr_range = "10.10.0.0/24"
  connection_preference    = "ACCEPT_AUTOMATIC"

  consumer_accept_lists = [
    {
      project_id_or_num = "consumer-project-id-or-number"
      connection_limit  = 5
    }
  ]
}
```

### Consumer (Endpoint) Example

This example creates a PSC endpoint to connect to the service attachment created in the producer example.

```terraform
module "psc_consumer" {
  source = "./" // Or your module source

  psc_type                  = "CONSUMER"
  project_id                = "your-consumer-project-id"
  region                    = "us-central1"
  name                      = "my-psc-endpoint"
  description               = "Endpoint for my-psc-service"
  network                   = "projects/your-consumer-project-id/global/networks/your-consumer-vpc"
  subnetwork                = "projects/your-consumer-project-id/regions/us-central1/subnetworks/your-consumer-subnet"
  target_service_attachment = module.psc_producer.service_attachment_uri
}
```

### Consumer for Google APIs Example

This example creates a PSC endpoint to connect to the `all-apis` Google API bundle, allowing private access to Google services from within your VPC.

```terraform
module "psc_google_apis_consumer" {
  source = "./" // Or your module source

  psc_type                  = "CONSUMER"
  project_id                = "your-project-id"
  region                    = "us-central1"
  name                      = "my-google-apis-endpoint"
  network                   = "projects/your-project-id/global/networks/your-vpc"
  subnetwork                = "projects/your-project-id/regions/us-central1/subnetworks/your-subnet"
  target_service_attachment = "all-apis"
  allow_psc_global_access   = true
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| psc\_type | The type of PSC setup to create. Must be one of 'PRODUCER' or 'CONSUMER'. | `string` | `null` | yes |
| name | The base name for the PSC resources. | `string` | `null` | yes |
| project\_id | The project ID where the PSC resources will be created. | `string` | `null` | yes |
| region | The region where the PSC resources will be created. | `string` | `null` | yes |
| network | The VPC network for the PSC resources. The network must be in the same project and region as the PSC resources. | `string` | `null` | yes |
| description | An optional description for the PSC resources. | `string` | `null` | no |
| **Producer Inputs** | | | | |
| target\_service | (Producer-only) The self-link of the forwarding rule of the internal load balancer to publish. | `string` | `null` | yes |
| connection\_preference | (Producer-only) The connection preference for the service attachment. Can be 'ACCEPT\_AUTOMATIC' or 'ACCEPT\_MANUAL'. | `string` | `"ACCEPT_AUTOMATIC"` | no |
| create\_nat\_subnet | (Producer-only) Whether to create a dedicated NAT subnet for the service attachment. If false, existing subnets must be provided via `nat_subnets`. | `bool` | `true` | no |
| nat\_subnet\_ip\_cidr\_range | (Producer-only) The IP CIDR range for the NAT subnet to be created. Required if `create_nat_subnet` is true. | `string` | `null` | no |
| nat\_subnets | (Producer-only) A list of self-links of existing NAT subnets to use for the service attachment. These are used in addition to the one created by the module if `create_nat_subnet` is true. | `list(string)` | `[]` | no |
| enable\_proxy\_protocol | (Producer-only) If true, indicates that connections to the service attachment will be proxied and the source IP address of the consumer instance will be preserved. | `bool` | `true` | no |
| consumer\_accept\_lists | (Producer-only) A list of projects that are allowed to connect to the service attachment. | `list(object({ project_id_or_num = string, connection_limit = number }))` | `[]` | no |
| consumer\_reject\_lists | (Producer-only) A list of projects that are not allowed to connect to the service attachment. | `list(string)` | `[]` | no |
| **Consumer Inputs** | | | | |
| target\_service\_attachment | (Consumer-only) The self-link of the service attachment to connect to, or a Google-managed service bundle like 'all-apis' or 'vpc-sc'. | `string` | `null` | yes |
| subnetwork | (Consumer-only) The self-link of the subnetwork where the PSC endpoint will be created. | `string` | `null` | yes |
| ip\_address | (Consumer-only) The self-link or IP address of a static internal IP address to use for the PSC endpoint. If not provided, a new one will be created. | `string` | `null` | no |
| allow\_psc\_global\_access | (Consumer-only) If true, the PSC endpoint can be accessed from any region. This is useful for endpoints connecting to Google APIs. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| service\_attachment | The created PSC service attachment resource. Only available when `psc_type` is 'PRODUCER'. |
| service\_attachment\_uri | The URI of the created service attachment, which is used by consumers. Only available when `psc_type` is 'PRODUCER'. |
| nat\_subnet | The PSC NAT subnet created by this module. Only available when `psc_type` is 'PRODUCER' and `create_nat_subnet` is true. |
| forwarding\_rule | The created PSC endpoint forwarding rule resource. Only available when `psc_type` is 'CONSUMER'. |
| endpoint\_ip\_address | The IP address of the PSC endpoint. Only available when `psc_type` is 'CONSUMER'. |
| ip\_address\_resource | The created static IP address resource for the PSC endpoint. Only available when `psc_type` is 'CONSUMER' and a value for `ip_address` is not provided. |

## Requirements

The following sections describe the requirements for using this module.

### Software

| Name | Version |
|------|---------|
| Terraform | >= 1.0 |
| terraform-provider-google | >= 4.50.0 |

### APIs

A project with the following APIs enabled is required:

-   Compute Engine API (`compute.googleapis.com`)

## Resources

| Name | Link |
|------|------|
| google\_compute\_service\_attachment | [docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_service_attachment) |
| google\_compute\_subnetwork | [docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) |
| google\_compute\_forwarding\_rule | [docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_forwarding_rule) |
| google\_compute\_address | [docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_address) |
