terraform {
  required_version = ">= 1.0, < 1.3.0"
  experiments = [ module_variable_optional_attrs ]
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
  }
}
