# Google Cloud Private Service Connect Module

This Terraform module simplifies the creation of [Private Service Connect (PSC)](https://cloud.google.com/vpc/docs/private-service-connect) resources in Google Cloud. It is designed to handle three distinct use cases, controlled by the `psc_type` variable:

1.  **`google_apis`**: Creates a PSC endpoint (a forwarding rule) to privately access Google APIs.
2.  **`consumer`**: Creates a PSC endpoint to privately consume a published third-party or internal service.
3.  **`producer`**: Publishes a service (fronted by an Internal Load Balancer) by creating a PSC service attachment and a dedicated NAT subnet.

This module abstracts the underlying resources, providing a unified interface for managing different aspects of the PSC lifecycle.

## Usage

Below are examples for each of the three primary use cases.

### 1. Connecting to Google APIs

This example creates a PSC endpoint that targets the `all-apis` bundle, allowing resources in the VPC to access Google APIs through a private IP address.

```hcl
module "psc_google_apis" {
  source     = "./" # Or path to your module
  psc_type   = "google_apis"
  project_id = "your-gcp-project-id"
  name       = "my-google-apis-endpoint"
  region     = "us-central1"
  network    = "projects/your-gcp-project-id/global/networks/my-vpc-network"
  subnetwork = "projects/your-gcp-project-id/regions/us-central1/subnetworks/my-subnet"

  # Optional: specify 'vpc-sc' bundle for VPC Service Controls
  # google_apis_bundle = "vpc-sc"
}
```

### 2. Consuming a Published Service

This example creates a PSC endpoint that connects to a service attachment published by another producer.

```hcl
module "psc_consumer_endpoint" {
  source     = "./" # Or path to your module
  psc_type   = "consumer"
  project_id = "your-gcp-project-id"
  name       = "my-consumer-endpoint"
  region     = "us-central1"
  network    = "projects/your-gcp-project-id/global/networks/my-vpc-network"
  subnetwork = "projects/your-gcp-project-id/regions/us-central1/subnetworks/my-subnet"

  # URI of the producer's service attachment
  service_attachment_uri = "projects/producer-project/regions/us-central1/serviceAttachments/producer-service"
}
```

### 3. Publishing a Service

This example creates a PSC service attachment to publish a service that is fronted by an Internal Load Balancer. It also creates the required PSC NAT subnet.

```hcl
module "psc_producer_service" {
  source     = "./" # Or path to your module
  psc_type   = "producer"
  project_id = "your-gcp-project-id"
  name       = "my-published-service"
  region     = "us-central1"
  network    = "projects/your-gcp-project-id/global/networks/my-vpc-network"

  # Self-link of the ILB forwarding rule to publish
  producer_ilb_forwarding_rule = "projects/your-gcp-project-id/regions/us-central1/forwardingRules/my-ilb-rule"

  # A dedicated CIDR range for the PSC NAT subnet
  psc_nat_subnet_cidr = "10.100.0.0/24"

  # Optional: set connection preference to manual approval
  # connection_preference = "ACCEPT_MANUAL"
}
```

## Requirements

Before this module can be used on a project, you must ensure that the following pre-requisites are fulfilled:

### Terraform
- Terraform `v1.3` or later.
- Terraform Provider for Google Cloud `~> 5.0`.

### APIs
The following APIs must be enabled on the project:
- Compute Engine API: `compute.googleapis.com`

### Roles
The service account or user running Terraform needs the following IAM roles on the specified project:
- `roles/compute.networkAdmin` (`Compute Network Admin`)

This role provides the necessary permissions to create and manage forwarding rules, addresses, subnets, and service attachments.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `psc_type` | The type of PSC resource to create. Must be one of: `google_apis`, `consumer`, `producer`. | `string` | `null` | yes |
| `name` | The name for the PSC resource (endpoint or service attachment). | `string` | `null` | yes |
| `project_id` | The project ID where the PSC resource will be created. | `string` | `null` | yes |
| `region` | The region where the PSC resource will be created. | `string` | `null` | yes |
| `network` | The self-link of the VPC network for the PSC resource. | `string` | `null` | yes |
| `subnetwork` | The self-link of the subnetwork for the consumer endpoint's IP address. | `string` | `null` | yes (if `psc_type` is `google_apis` or `consumer`) |
| `service_attachment_uri` | The URI of the producer's service attachment to connect to. | `string` | `null` | yes (if `psc_type` is `consumer`) |
| `producer_ilb_forwarding_rule` | The self-link of the Internal Load Balancer's forwarding rule to publish. | `string` | `null` | yes (if `psc_type` is `producer`) |
| `psc_nat_subnet_cidr` | The CIDR range for the PSC NAT subnet, which will be created automatically. | `string` | `null` | yes (if `psc_type` is `producer`) |
| `description` | An optional description for the PSC resource. | `string` | `null` | no |
| `google_apis_bundle` | The Google APIs bundle to connect to. Must be `all-apis` or `vpc-sc`. Only applicable when `psc_type` is `google_apis`. | `string` | `"all-apis"` | no |
| `global_access` | Whether to allow PSC global access for Google APIs endpoint. Only applicable when `psc_type` is `google_apis`. | `bool` | `true` | no |
| `connection_preference` | The connection preference for the service attachment. Can be `ACCEPT_AUTOMATIC` or `ACCEPT_MANUAL`. Only applicable when `psc_type` is `producer`. | `string` | `"ACCEPT_AUTOMATIC"` | no |
| `enable_proxy_protocol` | If true, enable the proxy protocol (version 1) to be used with this service attachment. Only applicable when `psc_type` is `producer`. | `bool` | `true` | no |

## Outputs

| Name | Description | Type |
|------|-------------|------|
| `endpoint_forwarding_rule_id` | The resource ID of the created PSC endpoint forwarding rule. This will be null if `psc_type` is `producer`. | `string` |
| `endpoint_ip_address` | The IP address of the created PSC endpoint. This will be null if `psc_type` is `producer`. | `string` |
| `service_attachment_id` | The resource ID of the created service attachment. This will be null if `psc_type` is `consumer` or `google_apis`. | `string` |
| `psc_nat_subnet_id` | The resource ID of the created PSC NAT subnet. This will be null if `psc_type` is `consumer` or `google_apis`. | `string` |
