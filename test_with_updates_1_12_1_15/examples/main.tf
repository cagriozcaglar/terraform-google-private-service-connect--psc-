# This file defines the resources needed to run a complete producer and consumer
# example of the Private Service Connect module.

# Use a random suffix to prevent naming collisions
resource "random_id" "suffix" {
  byte_length = 4
}

# ------------------------------------------------------------------------------
# PROVIDER CONFIGURATION
# ------------------------------------------------------------------------------

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# ------------------------------------------------------------------------------
# PRODUCER-SIDE PREREQUISITES
# These resources are required to create a service to expose via PSC.
# ------------------------------------------------------------------------------

# Producer VPC Network
resource "google_compute_network" "producer_vpc" {
  name                    = "psc-producer-vpc-${random_id.suffix.hex}"
  auto_create_subnetworks = false
}

# Subnet for the ILB and backends
resource "google_compute_subnetwork" "producer_subnet" {
  name          = "psc-producer-snet-${random_id.suffix.hex}"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.producer_vpc.self_link
  region        = var.region
}

# A simple instance template for the backend service
resource "google_compute_instance_template" "producer_backend_template" {
  name_prefix  = "producer-backend-tpl-"
  machine_type = "e2-micro"
  network_interface {
    network    = google_compute_network.producer_vpc.id
    subnetwork = google_compute_subnetwork.producer_subnet.id
  }
  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }
  metadata_startup_script = "#! /bin/bash\n sudo apt-get update\n sudo apt-get install -y apache2\n echo '<!doctype html><html><body><h1>PSC Producer</h1></body></html>' | sudo tee /var/www/html/index.html"
  tags                    = ["psc-producer-backend"]
}

# Managed instance group to serve as the backend
resource "google_compute_instance_group_manager" "producer_mig" {
  name               = "producer-mig-${random_id.suffix.hex}"
  base_instance_name = "producer-vm"
  zone               = "${var.region}-b"
  target_size        = 1
  version {
    instance_template = google_compute_instance_template.producer_backend_template.id
  }
}

# Health check for the ILB
resource "google_compute_health_check" "producer_ilb_hc" {
  name                = "producer-ilb-hc-${random_id.suffix.hex}"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
  tcp_health_check {
    port = "80"
  }
}

# Backend service for the ILB
resource "google_compute_backend_service" "producer_ilb_backend" {
  name                  = "producer-ilb-backend-${random_id.suffix.hex}"
  protocol              = "TCP"
  load_balancing_scheme = "INTERNAL"
  health_checks         = [google_compute_health_check.producer_ilb_hc.id]
  backend {
    group = google_compute_instance_group_manager.producer_mig.instance_group
  }
}

# Forwarding rule for the ILB (this is the service we will expose)
resource "google_compute_forwarding_rule" "producer_target_service" {
  name                  = "producer-ilb-fr-${random_id.suffix.hex}"
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_backend_service.producer_ilb_backend.id
  all_ports             = true
  network               = google_compute_network.producer_vpc.id
  subnetwork            = google_compute_subnetwork.producer_subnet.id
}

# ------------------------------------------------------------------------------
# CONSUMER-SIDE PREREQUISITES
# ------------------------------------------------------------------------------

# Consumer VPC Network
resource "google_compute_network" "consumer_vpc" {
  name                    = "psc-consumer-vpc-${random_id.suffix.hex}"
  auto_create_subnetworks = false
}

# Subnet for the PSC endpoint
resource "google_compute_subnetwork" "consumer_psc_subnet" {
  name          = "psc-consumer-snet-${random_id.suffix.hex}"
  ip_cidr_range = "10.0.2.0/24"
  network       = google_compute_network.consumer_vpc.self_link
  region        = var.region
}

# ------------------------------------------------------------------------------
# MODULE INVOCATIONS
# ------------------------------------------------------------------------------

# 1. Producer: Create the Service Attachment to expose the ILB
module "psc_producer" {
  source = "../../"

  psc_type              = "PRODUCER"
  name                  = "my-producer-service-${random_id.suffix.hex}"
  project_id            = var.project_id
  region                = var.region
  network               = google_compute_network.producer_vpc.self_link
  description           = "Example PSC producer service attachment"
  target_service        = google_compute_forwarding_rule.producer_target_service.self_link
  psc_nat_subnet_cidr   = "10.0.100.0/24"
  connection_preference = "ACCEPT_AUTOMATIC"

  # Optionally, auto-accept connections from the consumer project
  consumer_accept_lists = [
    {
      project_id_or_num = var.project_id
      connection_limit  = 5
    }
  ]
}

# 2. Consumer: Create the PSC Endpoint to connect to the producer's service
module "psc_consumer" {
  source = "../../"

  psc_type                  = "CONSUMER"
  name                      = "my-consumer-endpoint-${random_id.suffix.hex}"
  project_id                = var.project_id
  region                    = var.region
  network                   = google_compute_network.consumer_vpc.self_link
  description               = "Example PSC consumer endpoint"
  target_service_attachment = module.psc_producer.service_attachment.self_link
  psc_endpoint_subnet       = google_compute_subnetwork.consumer_psc_subnet.self_link
}
