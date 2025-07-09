terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Usa una versión compatible
    }
  }
}
provider "aws" {
  region = var.aws_region # Usamos una variable para la región
  access_key = "<ACCESS_KEY>"
  secret_key = "<SECRET_KEY>"
}
