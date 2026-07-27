variable "project" {
  description = "Project name."
  type        = string
  default     = "eks-multi-az-iac-poc"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets across."
  type        = number
  default     = 2
}

variable "cluster_version" {
  description = "EKS control-plane version"
  type        = string
  default     = "1.33"
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.micro"]
}

variable "node_capacity_type" {
  description = "SPOT (interruptible, cheap) or ON_DEMAND (stable)."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["SPOT", "ON_DEMAND"], var.node_capacity_type)
    error_message = "node_capacity_type must be SPOT or ON_DEMAND."
  }
}

variable "node_min_size" {
  description = "Minimum nodes in the managed node group."
  type        = number
  default     = 1
}

variable "node_desired_size" {
  description = "Desired nodes in the managed node group."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum nodes in the managed node group."
  type        = number
  default     = 2
}

variable "node_disk_size" {
  description = "EBS root volume size (GiB) per node."
  type        = number
  default     = 20
}

variable "app_deploy_role_arns" {
  description = "IAM roles the app CD pipeline (app-ci.yml) assumes."
  type        = map(string)
  default     = {}
}

variable "app_namespace" {
  description = "Namespace the app CD pipeline may edit."
  type        = string
  default     = "default"
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
