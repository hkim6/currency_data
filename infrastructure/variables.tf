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

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "image_repo" {
  description = "ECR repository name"
  type        = string
}

variable "security_group" {
  description = "Security group ID"
  type        = string
}