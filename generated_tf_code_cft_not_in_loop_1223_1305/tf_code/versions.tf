# Specifies the required version of Terraform.
terraform {
  required_version = ">= 1.3"
  # Specifies the required version for the Google Cloud provider.
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.54.0"
    }
  }
}
