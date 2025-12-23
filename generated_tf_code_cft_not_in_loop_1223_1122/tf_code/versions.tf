terraform {
  # Specifies the required version of Terraform.
  required_version = ">= 1.0"

  # Specifies the required provider and its version constraints.
  required_providers {
    google = {
      # The source of the Google Cloud provider.
      source = "hashicorp/google"
      # The required version of the Google Cloud provider.
      version = ">= 4.50.0"
    }
  }
}
