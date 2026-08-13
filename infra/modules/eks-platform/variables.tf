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
  description = "EKS control-plane version."
  type        = string
  default     = "1.33"

  validation {
    condition     = can(regex("^1\\.[0-9]{2}$", var.cluster_version))
    error_message = "cluster_version must be a minor version such as \"1.33\", never a patch version."
  }
}

variable "cluster_endpoint_public_access" {
  description = "Expose the Kubernetes API on a public endpoint, restricted to cluster_endpoint_public_access_cidrs. The private endpoint is always on."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for c in var.cluster_endpoint_public_access_cidrs : can(cidrhost(c, 0))])
    error_message = "every entry must be a valid CIDR, e.g. [\"203.0.113.4/32\"]."
  }
}

variable "cluster_enabled_log_types" {
  description = "Control-plane log types shipped to CloudWatch."
  type        = list(string)
  default     = ["api", "audit", "authenticator"]

  validation {
    condition     = alltrue([for t in var.cluster_enabled_log_types : contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], t)])
    error_message = "valid log types are api, audit, authenticator, controllerManager, scheduler."
  }
}

variable "cluster_log_retention_days" {
  description = "Retention for /aws/eks/<cluster>/cluster. The log group is created here rather than by EKS so this is not \"never expire\"."
  type        = number
  default     = 90
}

variable "kms_key_deletion_window_in_days" {
  description = "Waiting period before the secrets-encryption key is destroyed. Deleting the key makes every encrypted Secret unreadable, so leave headroom."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window_in_days >= 7 && var.kms_key_deletion_window_in_days <= 30
    error_message = "kms_key_deletion_window_in_days must be between 7 and 30."
  }
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Give the applying principal a cluster-admin access entry."
  type        = bool
  default     = true
}

################################################################################
# Access
################################################################################

variable "app_deploy_role_arns" {
  description = "IAM roles the app CD pipeline (app-ci.yml) assumes. Each gets an access entry scoped to app_namespace."
  type        = map(string)
  default     = {}
}

variable "app_namespace" {
  description = "Namespace the app CD pipeline may edit."
  type        = string
  default     = "default"
}

variable "cluster_admin_principal_arns" {
  description = "Principals granted cluster-admin. Terraform installs Helm releases now, so every identity that runs apply needs one. Never list the identity that CREATED the cluster: enable_cluster_creator_admin_permissions already made an access entry for it and a second one fails with ResourceInUseException. Apply locally, list the CI apply role here; let CI create the cluster, list your own ARN instead."
  type        = map(string)
  default     = {}
}

variable "cluster_viewer_principal_arns" {
  description = "Principals granted read access including Secrets (AmazonEKSAdminViewPolicy). What a Terraform plan identity needs to refresh Helm release state — releases are stored as Secrets — without handing it write access."
  type        = map(string)
  default     = {}
}

variable "cluster_viewer_namespaces" {
  description = "Namespaces the viewer principals may read. Defaults to where Helm keeps its release Secrets; an empty list widens the grant to the whole cluster, which means every Secret in it."
  type        = list(string)
  default     = ["ingress-nginx"]
}

################################################################################
# Ingress
################################################################################

variable "enable_ingress_nginx" {
  description = "Install ingress-nginx and its NLB."
  type        = bool
  default     = true
}

variable "ingress_nginx_chart_version" {
  description = "ingress-nginx Helm chart version. "
  type        = string
  default     = "4.15.1"
}

variable "ingress_nginx_replica_count" {
  description = "Controller replicas. Two is the minimum that survives a node going away; they spread across AZs."
  type        = number
  default     = 2
}

variable "ingress_hostname" {
  description = "FQDN pointed at the ingress NLB, e.g. app.example.com. Empty means no Route 53 record — the NLB's own DNS name is then the only way in."
  type        = string
  default     = ""
}

variable "route53_zone_name" {
  description = "Public hosted zone that owns ingress_hostname."
  type        = string
  default     = "euclecio.site"
}

################################################################################
# Node group
################################################################################

variable "node_ami_type" {
  description = "Managed node group AMI family."
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "node_instance_types" {
  description = "Instance types for the managed node group. With SPOT, list several so the group has more than one capacity pool to fall back on."
  type        = list(string)
  default     = ["t3.micro"]

  validation {
    condition     = length(var.node_instance_types) > 0
    error_message = "node_instance_types must not be empty."
  }
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

  validation {
    condition     = var.node_min_size <= var.node_desired_size && var.node_desired_size <= var.node_max_size
    error_message = "node sizes must satisfy min <= desired <= max."
  }
}

variable "node_disk_size" {
  description = "EBS root volume size (GiB) per node. Applied through the launch template's block_device_mappings, not the node group."
  type        = number
  default     = 20

  validation {
    condition     = var.node_disk_size >= 20
    error_message = "node_disk_size must be at least 20 GiB to hold the AMI plus images."
  }
}

variable "node_volume_type" {
  description = "EBS root volume type per node. gp3 gives gp2's baseline IOPS for less money and lets throughput be raised without growing the volume."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2"], var.node_volume_type)
    error_message = "node_volume_type must be gp3 or gp2."
  }
}

variable "node_imds_hop_limit" {
  description = "IMDSv2 PUT response hop limit. 1 keeps the node role's credentials out of pods on the pod network; raise to 2 only for a workload that genuinely reads IMDS from inside a container."
  type        = number
  default     = 1

  validation {
    condition     = var.node_imds_hop_limit >= 1 && var.node_imds_hop_limit <= 2
    error_message = "node_imds_hop_limit must be 1 or 2."
  }
}
