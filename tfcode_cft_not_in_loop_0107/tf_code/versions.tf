terraform {
  # This module supports Terraform version 1.3 and newer.
  required_version = ">= 1.3"

  # This module requires the Google Provider.
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0"
    }
  }
}
