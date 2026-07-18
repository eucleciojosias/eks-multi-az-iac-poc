output "region" {
  description = "AWS region the infra is deployed in."
  value       = var.region
}

output "cluster_name" {
  description = "EKS cluster name (used by `make kubeconfig`)."
  value       = var.cluster_name
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (EKS nodes live here)."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs (load balancers, NAT)."
  value       = module.vpc.public_subnets
}

output "azs" {
  description = "Availability Zones in use."
  value       = local.azs
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_provider_arn" {
  description = "OIDC provider ARN (used for IRSA)."
  value       = module.eks.oidc_provider_arn
}

output "node_group_names" {
  description = "Managed node group name(s)."
  value       = keys(module.eks.eks_managed_node_groups)
}
