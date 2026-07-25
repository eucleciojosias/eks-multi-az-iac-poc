module "platform" {
  source = "../../modules/eks-platform"

  project     = "eks-multi-az-iac-poc"
  environment = "staging"

  # Staging overrides — everything else uses the module's production-posture
  # defaults (ON_DEMAND, KMS on, endpoint CIDR 0.0.0.0/0 which you'd tighten).
  node_capacity_type  = "SPOT"
  node_instance_types = ["t3.small", "t3.medium"]
  node_desired_size   = 2
}
