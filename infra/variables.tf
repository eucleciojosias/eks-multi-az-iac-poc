variable "project" {
  description = "Project name, used for tagging and resource naming."
  type        = string
  default     = "eks-multi-az-iac-poc"
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}
