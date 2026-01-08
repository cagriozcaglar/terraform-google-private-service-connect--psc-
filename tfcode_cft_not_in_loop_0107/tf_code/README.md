# Google Cloud Private Service Connect Module

This Terraform module simplifies the creation and management of Google Cloud Private Service Connect (PSC) resources. It is designed to operate in one of three mutually exclusive modes:

1.  **Producer Mode**: Creates a Service Attachment to publish a service (an Internal Load Balancer) for consumption by other VPC networks. This mode also handles the creation of the required PSC NAT subnets.
2.  **Consumer Service Mode**: Creates a PSC endpoint (a forwarding rule) to privately connect to a published service from another VPC network.
3.  **Consumer Google APIs Mode**: Creates a PSC endpoint (a global forwarding rule) to privately connect to Google APIs (e.g., Cloud Storage, BigQuery) without traversing the public internet.

The module validates its inputs to ensure it is configured for exactly one of these modes, preventing misconfiguration.

## Usage

Below are examples for each of the three operating modes.

### Producer Mode

This example creates a Service Attachment to publish an existing Internal Load Balancer. It also creates the necessary PSC NAT subnets.

```hcl
module "psc_producer" {
  source = "./" # Replace with module source

  project_id            = "my-producer-project-id"
  name                  = "my-published-service"
  region                = "us-central1"
  network               = "projects/my-producer-project-id/global/networks/my-vpc"
  target_service        = "projects/my-producer-project-id/regions/us-central1/forwardingRules/my-ilb-forwarding-rule"
  psc_nat_subnets       = ["10.10.0.0/24"]
  connection_preference = "ACCEPT_AUTOMATIC"

  consumer_accept_list = [
    {
      project_id_or_num = "my-consumer-project-id"
      connection_limit  = 5
    }
  ]
}
```

### Consumer Service Mode

This example creates a PSC endpoint to connect to a service published by a producer.

```hcl
module "psc_consumer" {
  source = "./" # Replace with module source

  project_id                = "my-consumer-project-id"
  name                      = "my-psc-endpoint"
  region                    = "us-central1"
  network                   = "projects/my-consumer-project-id/global/networks/my-consumer-vpc"
  subnetwork                = "projects/my-consumer-project-id/regions/us-central1/subnetworks/my-subnet"
  target_service_attachment = "projects/producer-project/regions/us-central1/serviceAttachments/producer-service"
}
```

### Consumer Google APIs Mode

This example creates a global PSC endpoint to access all Google APIs privately.

```hcl
module "psc_google_apis" {
  source = "./" # Replace with module source

  project_id          = "my-gapis-project-id"
  name                = "psc-to-google-apis"
  network             = "projects/my-gapis-project-id/global/networks/my-vpc"
  google_apis_bundle  = "all-apis"
  global_address_ip   = "10.20.0.10"
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.50.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_connection_preference"></a> [connection\_preference](#input\_connection\_preference) | PRODUCER MODE: The connection preference for the service attachment. Can be ACCEPT\_AUTOMATIC or ACCEPT\_MANUAL. | `string` | `"ACCEPT_MANUAL"` | no |
| <a name="input_consumer_accept_list"></a> [consumer\_accept\_list](#input\_consumer\_accept\_list) | PRODUCER MODE: A list of projects that are allowed to connect to this service attachment. | <pre>list(object({<br>    project_id_or_num = string<br>    connection_limit  = number<br>  }))</pre> | `[]` | no |
| <a name="input_description"></a> [description](#input\_description) | An optional description to apply to the created PSC resources. | `string` | `"Private Service Connect resource managed by Terraform"` | no |
| <a name="input_enable_proxy_protocol"></a> [enable\_proxy\_protocol](#input\_enable\_proxy\_protocol) | PRODUCER MODE: If true, the PROXY protocol header will be sent to the backend service. | `bool` | `false` | no |
| <a name="input_global_address_ip"></a> [global\_address\_ip](#input\_global\_address\_ip) | CONSUMER GOOGLE APIS MODE: The specific IP address to reserve for the global PSC endpoint. This must be a valid IP address. | `string` | `null` | no |
| <a name="input_google_apis_bundle"></a> [google\_apis\_bundle](#input\_google\_apis\_bundle) | CONSUMER GOOGLE APIS MODE: The target Google APIs bundle to connect to (e.g., 'all-apis' or 'vpc-sc'). Setting this variable activates consumer Google APIs mode. | `string` | `null` | no |
| <a name="input_ip_address"></a> [ip\_address](#input\_ip\_address) | CONSUMER SERVICE MODE: A reserved static internal IP address to use for the PSC endpoint. If not provided, a new one will be created. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | The base name for the PSC resources being created. | `string` | `null` | yes |
| <a name="input_network"></a> [network](#input\_network) | The self-link of the VPC network where the PSC resources will be created. | `string` | `null` | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project ID where the PSC resources will be created. | `string` | `null` | yes |
| <a name="input_psc_nat_subnets"></a> [psc\_nat\_subnets](#input\_psc\_nat\_subnets) | PRODUCER MODE: A list of CIDR ranges for the PSC NAT subnets to be created. These subnets are used for the service attachment. | `list(string)` | `[]` | no |
| <a name="input_reconcile_connections"></a> [reconcile\_connections](#input\_reconcile\_connections) | PRODUCER MODE: If true, connections from consumers in the same project are automatically accepted. | `bool` | `true` | no |
| <a name="input_region"></a> [region](#input\_region) | The region for the PSC resources. Not used for the 'Google APIs' mode, which creates global resources. | `string` | `null` | no |
| <a name="input_subnetwork"></a> [subnetwork](#input\_subnetwork) | CONSUMER SERVICE MODE: The self-link of the subnetwork where the PSC endpoint's IP will be allocated. | `string` | `null` | no |
| <a name="input_target_service"></a> [target\_service](#input\_target\_service) | PRODUCER MODE: The self-link of the Internal Load Balancer's forwarding rule to be published. Setting this variable activates producer mode. | `string` | `null` | no |
| <a name="input_target_service_attachment"></a> [target\_service\_attachment](#input\_target\_service\_attachment) | CONSUMER SERVICE MODE: The URI of the producer's Service Attachment to connect to. Setting this variable activates consumer service mode. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_consumer_forwarding_rule"></a> [consumer\_forwarding\_rule](#output\_consumer\_forwarding\_rule) | The created consumer forwarding rule resource. Only available in consumer modes. |
| <a name="output_consumer_ip_address"></a> [consumer\_ip\_address](#output\_consumer\_ip\_address) | The IP address of the created consumer endpoint. Only available in consumer modes. |
| <a name="output_nat_subnets"></a> [nat\_subnets](#output\_nat\_subnets) | A map of the created PSC NAT subnets, keyed by their self-link. Only available in producer mode. |
| <a name="output_psc_connection_id"></a> [psc\_connection\_id](#output\_psc\_connection\_id) | The connection ID of the PSC forwarding rule. Only available in consumer service mode. |
| <a name="output_service_attachment"></a> [service\_attachment](#output\_service\_attachment) | The created service attachment resource. Only available in producer mode. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
