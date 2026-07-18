module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # API endpoint: public + private. Auth is always required; restrict the public
  # side with cluster_endpoint_public_access_cidrs (default 0.0.0.0/0 for a POC).
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Modern auth: EKS access entries (API mode). This flag adds an access entry
  # granting the identity that runs `apply` cluster-admin — replaces the old
  # aws-auth ConfigMap dance.
  enable_cluster_creator_admin_permissions = true

  # OIDC provider for IRSA (pods assume IAM roles without static keys).
  enable_irsa = true

  # Secrets envelope encryption at rest with a dedicated KMS key (module creates
  # + rotates it). The Terraform IAM policy includes a matching kms:* statement.
  create_kms_key            = true
  cluster_encryption_config = { resources = ["secrets"] }

  # Nodes live in the PRIVATE subnets; the control plane is AWS-managed.
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    # AL2023 is the current EKS-optimized AMI family (AL2 is being retired).
    ami_type = "AL2023_x86_64_STANDARD"
  }

  eks_managed_node_groups = {
    default = {
      # Keep the node IAM role within the eks-multi-az-iac-poc-* prefix so the
      # scoped Terraform IAM policy is allowed to create it (module default
      # would be "default-eks-node-group-*", which the policy denies).
      iam_role_name            = "${var.cluster_name}-node"
      iam_role_use_name_prefix = true

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      instance_types = var.node_instance_types
      capacity_type  = "SPOT" # cost lever; interruptible, fine for a POC

      disk_size = var.node_disk_size
    }
  }

  tags = {
    Project = var.project
  }
}
