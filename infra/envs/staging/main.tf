module "platform" {
  source = "../../modules/eks-platform"

  project     = "eks-multi-az-iac-poc"
  environment = "staging"

  node_ami_type       = "AL2023_x86_64_STANDARD"
  node_capacity_type  = "SPOT"
  node_instance_types = ["t3.small"]
  node_desired_size   = 2

  ingress_hostname = "app.staging.euclecio.site"

  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  app_deploy_role_arns = local.principals.app_cd

  cluster_admin_principal_arns  = merge(local.principals.tf_apply, local.principals.local_admin)
  cluster_viewer_principal_arns = local.principals.tf_plan
}

locals {
  # Each is optional: unset in a GitHub Environment, TF_VAR_* arrives as "".
  principals = {
    for k, arn in {
      app_cd      = var.app_deploy_role_arn
      tf_apply    = var.tf_apply_role_arn
      tf_plan     = var.tf_plan_role_arn
      local_admin = var.local_admin_principal_arn
    } : k => arn == null || arn == "" ? {} : { (k) = arn }
  }
}