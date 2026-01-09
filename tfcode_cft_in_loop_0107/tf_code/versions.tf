# Specifies the Terraform version and required providers.
terraform {
  # Specifies the minimum required version of Terraform.
  required_version = ">= 1.0"
  # Defines the required providers for this module.
  required_providers {
    # Defines the Google Cloud provider.
    google = {
      # The official source for the Google Cloud provider.
      source  = "hashicorp/google"
      # Specifies the minimum required version of the Google Cloud provider.
      version = ">= 4.50.0"
    }
  }
}
