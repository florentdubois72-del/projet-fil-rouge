terraform {
  required_version = "~> 1.14.5"
  required_providers {
    aws = {
      version = "~> 4.16"
      source  = "hashicorp/aws"
    }
  }
}
