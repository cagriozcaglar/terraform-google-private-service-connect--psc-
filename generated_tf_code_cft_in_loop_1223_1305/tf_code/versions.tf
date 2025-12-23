# This file is for the Terraform provider configuration.
# It specifies the required provider and its version.
terraform {
  # This block specifies the minimum version of Terraform that can be used with this module.
  required_version = ">= 1.3"

  # This block specifies the providers required by this module.
  required_providers {
    # The Google Provider is used to manage Google Cloud resources.
    google = {
      # The source of the Google provider, specifying where to download it from.
      source = "hashicorp/google"
      # The version constraint for the Google provider, ensuring compatibility.
      version = "~> 5.0"
    }
  }
}
