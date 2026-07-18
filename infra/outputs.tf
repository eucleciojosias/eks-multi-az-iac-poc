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
