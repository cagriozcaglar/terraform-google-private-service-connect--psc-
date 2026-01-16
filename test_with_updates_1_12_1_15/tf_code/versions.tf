# The versions.tf file is used to specify the version of Terraform and the providers that the module depends on.
# By specifying version constraints, you can ensure that your module is compatible with the correct versions of Terraform and the providers,
# and prevent unexpected issues that may arise from using incompatible versions.

terraform {
  # This module is tested with Terraform 1.3 and requires at least this version.
  required_version = ">= 1.3.0"

  required_providers {
    # The Google Provider is used to manage Google Cloud Platform resources.
    google = {
      source  = "hashicorp/google"
      version = ">= 4.54.0"
    }
    # The Google Beta Provider is used for resources and features that are not yet generally available.
    # Service Attachment is managed via the beta provider.
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 4.54.0"
    }
  }
}
