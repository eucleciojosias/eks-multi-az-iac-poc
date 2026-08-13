output "region" {
  description = "AWS region the infra is deployed in."
  value       = data.aws_region.current.name
}

output "cluster_name" {
  description = "EKS cluster name (used by `make update-kubeconfig`)."
  value       = module.eks.cluster_name
}

output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (EKS nodes live here)."
  value       = [for s in aws_subnet.private : s.id]
}

output "public_subnet_ids" {
  description = "Public subnet IDs (load balancers, NAT)."
  value       = [for s in aws_subnet.public : s.id]
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
