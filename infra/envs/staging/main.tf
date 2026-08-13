module "platform" {
  source = "../../modules/eks-platform"

  project     = "eks-multi-az-iac-poc"
  environment = "staging"

  node_ami_type       = "AL2023_x86_64_STANDARD"
  node_capacity_type  = "SPOT"
  node_instance_types = ["t3.small"]
  node_desired_size   = 2

  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  app_deploy_role_arns = var.app_deploy_role_arn == null || var.app_deploy_role_arn == "" ? {} : { app_cd = var.app_deploy_role_arn }
}