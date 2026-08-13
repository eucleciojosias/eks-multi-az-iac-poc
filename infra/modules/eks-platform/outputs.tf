output "region" {
  description = "AWS region the infra is deployed in."
  value       = data.aws_region.current.name
}

output "azs" {
  description = "Availability Zones in use."
  value       = local.azs
}

################################################################################
# Network
################################################################################

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

################################################################################
# Cluster
################################################################################

output "cluster_name" {
  description = "EKS cluster name (used by `make update-kubeconfig`)."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 CA bundle for the API server — for building a kubeconfig without calling AWS."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "EKS-managed cluster security group. Reference it from other security groups instead of opening CIDRs."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_oidc_provider_arn" {
  description = "OIDC provider ARN (used for IRSA)."
  value       = aws_iam_openid_connect_provider.this.arn
}

output "cluster_oidc_issuer_host" {
  description = "Issuer host without the scheme — the prefix for IRSA trust-policy condition keys."
  value       = local.oidc_issuer_host
}

################################################################################
# Compute
################################################################################

output "node_group_names" {
  description = "Managed node group name(s)."
  value       = [aws_eks_node_group.default.node_group_name]
}

################################################################################
# Ingress
################################################################################

output "ingress_url" {
  description = "Where the cluster answers. Without a hostname, read the NLB name from `kubectl -n ingress-nginx get svc ingress-nginx-controller`."
  value       = local.create_ingress_record ? "https://${var.ingress_hostname}" : null
}

output "ingress_nlb_dns_name" {
  description = "DNS name of the NLB the cloud controller created for the ingress Service."
  value       = local.create_ingress_record ? data.aws_lb.ingress[0].dns_name : null
}

output "node_iam_role_arn" {
  description = "IAM role the nodes assume — the principal to grant when a workload uses the node role instead of IRSA."
  value       = aws_iam_role.node.arn
}
