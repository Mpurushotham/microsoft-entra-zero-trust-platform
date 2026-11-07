terraform {
  required_version = ">= 1.9"

  required_providers {
    msgraph = {
      source  = "microsoft/msgraph"
      version = "~> 0.6"
    }
  }
}
