variable "aws_region" {
  description = "Region: Ohio"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Digital library, Secretos para contar app"
  type        = string
  default     = "Secretos para contar app"
}

variable "vpc_cidr_block" {
  description = "Bloque CIDR para la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  description = "Bloque CIDR para la subred pública."
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type_frontend" {
  description = "Frontend instance: EC2"
  type        = string
  default     = "t2.micro" 
}

variable "instance_type_backend" {
  description = "Backend instance: EC2"
  type        = string
  default     = "t2.micro" 
}

variable "ami_id" {
  description = "AMI: Amazon Linux"
  type        = string
  default     = "ami-0c803b171269e2d72"
}

variable "key_pair_name" {
  description = "Key pair name: terraform-cloud5"
  type        = string
  default     = "terraform-cloud5"
}
