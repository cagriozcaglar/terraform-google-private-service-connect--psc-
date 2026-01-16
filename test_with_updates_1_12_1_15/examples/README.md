# Full Producer and Consumer Example

This example demonstrates how to use the Private Service Connect (PSC) module to create a complete, working producer and consumer setup within the same Google Cloud project.

## What this example does:

1.  **Producer Setup**:
    *   Creates a dedicated VPC network (`producer-vpc`).
    *   Deploys a simple web server on a managed instance group.
    *   Sets up an internal TCP load balancer to front the web server.
    *   Uses the `psc` module in `PRODUCER` mode to create a **Service Attachment**, securely exposing the internal load balancer.
    *   Creates a dedicated PSC NAT subnet for the service attachment.

2.  **Consumer Setup**:
    *   Creates a separate VPC network (`consumer-vpc`).
    *   Uses the `psc` module in `CONSUMER` mode to create a **PSC Endpoint** (a forwarding rule) that connects to the producer's Service Attachment.
    *   The endpoint gets a private IP address from a subnet within the consumer's VPC.

This configuration allows resources within the `consumer-vpc` to access the service in the `producer-vpc` via a private, secure connection, without either VPC needing to be peered or having overlapping IP ranges.

## How to use this example:

1.  **Configure your environment:**
    *   Make sure you have authenticated with the gcloud CLI: `gcloud auth application-default login`
    *   Ensure the Compute Engine API is enabled in your project: `gcloud services enable compute.googleapis.com --project <YOUR_PROJECT_ID>`

2.  **Deploy the resources:**
    *   Navigate to this directory.
    *   Initialize Terraform:
