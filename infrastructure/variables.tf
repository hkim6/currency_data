variable "region" {
  default = "us-east-2"
}

variable "db_username" {
  description = "Master DB username"
  type        = string
}

variable "db_password" {
  description = "Master DB password"
  type        = string
  sensitive   = true
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}