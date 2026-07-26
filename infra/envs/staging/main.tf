module "platform" {
  source = "../../modules/eks-platform"

  project     = "eks-multi-az-iac-poc"
  environment = "staging"

  node_capacity_type  = "SPOT"
  node_instance_types = ["t3.micro"]
  node_desired_size   = 2

  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
}