# Google Cloud Private Service Connect (PSC) Module

This module handles the creation of Google Cloud Private Service Connect (PSC) resources. It is designed to support three distinct use cases, controlled by the `psc_type` variable:

1.  **PRODUCER**: Creates a Service Attachment (`google_compute_service_attachment`) to publish a managed service, allowing consumers to connect to it privately from their own VPCs.
2.  **CONSUMER\_SERVICE**: Creates a PSC endpoint (`google_compute_forwarding_rule`) to connect to a published third-party or internal service.
3.  **CONSUMER\_GOOGLE\_APIS**: Creates a PSC endpoint (`google_compute_forwarding_rule`) for the `all-apis` bundle to privately access Google APIs from within a consumer VPC.

By setting the `psc_type` variable, you can instantiate the correct set of resources for your specific scenario. If `psc_type` is set to `null`, no resources will be created.

## Usage

Below are examples for each of the three primary use cases.

### Producer: Publish a Managed Service

This example creates a Service Attachment to expose an Internal Load Balancer (`target_service`) to consumers.

```hcl
module "psc_producer" {
  source                  = "./" # Or your module source
  psc_type                = "PRODUCER"
  project_id              = "your-producer-project-id"
  region                  = "us-central1"
  name                    = "my-published-service"
  description             = "Service attachment for my-app"
  target_service          = "projects/your-producer-project-id/regions/us-central1/forwardingRules/my-ilb-forwarding-rule"
  nat_subnets             = ["projects/your-producer-project-id/regions/us-central1/subnetworks/my-psc-nat-subnet"]
  connection_preference   = "ACCEPT_AUTOMATIC"
  enable_proxy_protocol   = false

  consumer_accept_list = [
    {
      project_id_or_num = "consumer-project-one-id"
      connection_limit  = 5
    }
  ]
}
```

### Consumer: Connect to a Published Service

This example creates a PSC endpoint (Forwarding Rule) in a consumer VPC to connect to a producer's Service Attachment.

```hcl
module "psc_consumer_service" {
  source                    = "./" # Or your module source
  psc_type                  = "CONSUMER_SERVICE"
  project_id                = "your-consumer-project-id"
  region                    = "us-central1"
  name                      = "my-connection-to-service"
  description               = "PSC endpoint for my-app service"
  network                   = "projects/your-consumer-project-id/global/networks/my-consumer-vpc"
  subnetwork                = "projects/your-consumer-project-id/regions/us-central1/subnetworks/my-consumer-subnet"
  target_service_attachment = "projects/producer-project-id/regions/us-central1/serviceAttachments/my-published-service"
  # Optional: specify a static IP address
  # ip_address                = "10.0.1.100"
}
```

### Consumer: Connect to Google APIs

This example creates a PSC endpoint for the `all-apis` bundle, allowing private access to supported Google APIs and Services from within a VPC.

```hcl
module "psc_google_apis" {
  source      = "./" # Or your module source
  psc_type    = "CONSUMER_GOOGLE_APIS"
  project_id  = "your-consumer-project-id"
  region      = "us-central1"
  name        = "private-google-apis-endpoint"
  description = "PSC endpoint for the all-apis bundle"
  network     = "projects/your-consumer-project-id/global/networks/my-consumer-vpc"
  subnetwork  = "projects/your-consumer-project-id/regions/us-central1/subnetworks/my-consumer-subnet"
  ip_address  = "10.0.1.53" # A static IP is recommended for Google APIs
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.50.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_psc_global_access"></a> [allow\_psc\_global\_access](#input\_allow\_psc\_global\_access) | CONSUMER\_SERVICE only. If true, allows the PSC endpoint to be accessed from all regions. | `bool` | `false` | no |
| <a name="input_connection_preference"></a> [connection\_preference](#input\_connection\_preference) | PRODUCER only. The connection preference for the service attachment. Valid values are 'ACCEPT\_AUTOMATIC' or 'ACCEPT\_MANUAL'. | `string` | `"ACCEPT_MANUAL"` | no |
| <a name="input_consumer_accept_list"></a> [consumer\_accept\_list](#input\_consumer\_accept\_list) | PRODUCER only. A list of projects that are allowed to connect to this service attachment. | <pre>list(object({<br>    project_id_or_num = string<br>    connection_limit  = number<br>  }))</pre> | `[]` | no |
| <a name="input_consumer_reject_list"></a> [consumer\_reject\_list](#input\_consumer\_reject\_list) | PRODUCER only. A list of project IDs or numbers that are not allowed to connect to this service attachment. | `list(string)` | `[]` | no |
| <a name="input_description"></a> [description](#input\_description) | An optional description for the PSC resource. | `string` | `null` | no |
| <a name="input_enable_proxy_protocol"></a> [enable\_proxy\_protocol](#input\_enable\_proxy\_protocol) | PRODUCER only. If true, the PROXY protocol header is enabled. | `bool` | `false` | no |
| <a name="input_ip_address"></a> [ip\_address](#input\_ip\_address) | CONSUMER only. An optional static internal IP address for the PSC endpoint. If not provided, an ephemeral address from the subnetwork is allocated. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The name for the Private Service Connect resource (Service Attachment or Forwarding Rule). Required when `psc_type` is not null. | `string` | `null` | no |
| <a name="input_nat_subnets"></a> [nat\_subnets](#input\_nat\_subnets) | PRODUCER only. A list of self-links for the PSC NAT subnets. These subnets are used to source NAT traffic from consumers. | `list(string)` | `[]` | no |
| <a name="input_network"></a> [network](#input\_network) | CONSUMER only. The self-link of the consumer's VPC network where the PSC endpoint will be created. | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project ID where the Private Service Connect resource will be created. Required when `psc_type` is not null. | `string` | `null` | no |
| <a name="input_psc_type"></a> [psc\_type](#input\_psc\_type) | The type of PSC resource to create. If null, no resource will be created. Must be one of: 'PRODUCER', 'CONSUMER\_SERVICE', 'CONSUMER\_GOOGLE\_APIS'. | `string` | `null` | no |
| <a name="input_reconcile_connections"></a> [reconcile\_connections](#input\_reconcile\_connections) | PRODUCER only. If true, connections that are not explicitly accepted are rejected. | `bool` | `true` | no |
| <a name="input_region"></a> [region](#input\_region) | The region where the Private Service Connect resource will be created. Required when `psc_type` is not null. | `string` | `null` | no |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | CONSUMER only. The self-link of the subnetwork where the endpoint's IP address will be allocated. | `string` | `null` | no |
| <a name="input_target_service"></a> [target\_service](#input\_target\_service) | PRODUCER only. The full self-link or ID of the internal load balancer's forwarding rule that fronts the service. | `string` | `null` | no |
| <a name="input_target_service_attachment"></a> [target\_service\_attachment](#input\_target\_service\_attachment) | CONSUMER\_SERVICE only. The full resource URI of the producer's service attachment to connect to. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_forwarding_rule"></a> [forwarding\_rule](#output\_forwarding\_rule) | The created `google_compute_forwarding_rule` resource object for consumer endpoints. This will be null if `psc_type` is 'PRODUCER' or if no resource is created. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the created Private Service Connect resource. |
| <a name="output_ip_address"></a> [ip\_address](#output\_ip\_address) | The internal IP address of the created consumer PSC endpoint. This will be null if `psc_type` is 'PRODUCER' or if no resource is created. |
| <a name="output_self_link"></a> [self\_link](#output\_self\_link) | The self-link of the created Private Service Connect resource. For producers, this is the service attachment URI to be shared with consumers. |
| <a name="output_service_attachment"></a> [service\_attachment](#output\_service\_attachment) | The created `google_compute_service_attachment` resource object for producers. This will be null if `psc_type` is not 'PRODUCER' or if no resource is created. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
