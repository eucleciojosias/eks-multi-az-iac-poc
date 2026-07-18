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

variable "cluster_version" {
  description = "EKS control-plane version (1.29-1.33 currently supported). Verify with `aws eks describe-cluster-versions`."
  type        = string
  default     = "1.33"
}

variable "node_instance_types" {
  description = "Instance types for the managed node group (spot picks the cheapest available)."
  type        = list(string)
  default     = ["t3.small", "t3.medium"]
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
  default     = 3
}

variable "node_disk_size" {
  description = "EBS root volume size (GiB) per node."
  type        = number
  default     = 20
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint. Lock to your IP/32 for real use; 0.0.0.0/0 is open to the internet (auth still required)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
