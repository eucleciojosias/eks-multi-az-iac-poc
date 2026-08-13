################################################################################
# Naming
################################################################################

variable "project" {
  description = "Project name. Prefixes every resource and every IAM role, which is what keeps them inside the scoped provisioner policy's role/<project>-* pattern."
  type        = string
  default     = "eks-multi-az-iac-poc"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,30}[a-z0-9]$", var.project))
    error_message = "project must be lowercase alphanumeric with hyphens, 3-32 characters."
  }
}

variable "environment" {
  description = "Environment name. Suffixes every resource so two envs can share one account."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,14}[a-z0-9]$", var.environment))
    error_message = "environment must be lowercase alphanumeric with hyphens, 2-16 characters."
  }
}

variable "tags" {
  description = "Extra tags merged into every resource. Project/Environment/ManagedBy are always applied."
  type        = map(string)
  default     = {}
}

################################################################################
# Network
################################################################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Split into /20s: private subnets from the low half, public from the high half."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) <= 20
    error_message = "vpc_cidr must be a valid CIDR of /20 or larger to fit the subnet layout."
  }
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets across."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 8
    error_message = "az_count must be between 2 (the EKS minimum) and 8 (the subnet layout's ceiling)."
  }
}

variable "single_nat_gateway" {
  description = "Share one NAT gateway across all AZs. Saves ~$32/AZ/month but makes private egress a single point of failure — non-production only."
  type        = bool
  default     = true
}

################################################################################
# Cluster
################################################################################

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
