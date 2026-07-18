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

variable "cluster_name" {
  description = "EKS cluster name; also used for k8s subnet ownership tags."
  type        = string
  default     = "eks-multi-az-iac-poc"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets across."
  type        = number
  default     = 3
}
