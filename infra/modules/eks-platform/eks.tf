resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${local.name}/cluster"
  retention_in_days = var.cluster_log_retention_days

  tags = merge(local.tags, { Name = "/aws/eks/${local.name}/cluster" })
}

resource "aws_eks_cluster" "this" {
  name     = local.name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  enabled_cluster_log_types = var.cluster_enabled_log_types

  access_config {
    authentication_mode = "API"

    # Applied once, at creation. Changing it later replaces the cluster.
    bootstrap_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  }

  vpc_config {
    subnet_ids = [for s in aws_subnet.private : s.id]

    endpoint_private_access = true
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }

  encryption_config {
    resources = ["secrets"]

    provider {
      key_arn = aws_kms_key.eks.arn
    }
  }

  tags = local.tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_iam_role_policy.cluster_encryption,
    aws_cloudwatch_log_group.cluster,
  ]
}

################################################################################
# IRSA
################################################################################

locals {
  oidc_issuer_host = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

resource "aws_iam_openid_connect_provider" "this" {
  url            = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]

  tags = local.tags
}

################################################################################
# Access entries
################################################################################

resource "aws_eks_access_entry" "app_deploy" {
  for_each = var.app_deploy_role_arns

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"

  tags = local.tags
}

locals {
  cluster_access = merge(
    { for k, arn in var.cluster_admin_principal_arns : k => {
      principal_arn = arn
      policy        = "AmazonEKSClusterAdminPolicy"
      namespaces    = []
    } },
    { for k, arn in var.cluster_viewer_principal_arns : k => {
      principal_arn = arn
      policy        = "AmazonEKSAdminViewPolicy"
      namespaces    = var.cluster_viewer_namespaces
    } },
  )
}

resource "aws_eks_access_entry" "cluster_access" {
  for_each = local.cluster_access

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  type          = "STANDARD"

  tags = local.tags
}

resource "aws_eks_access_policy_association" "cluster_access" {
  for_each = local.cluster_access

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value.principal_arn
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/${each.value.policy}"

  access_scope {
    type       = length(each.value.namespaces) > 0 ? "namespace" : "cluster"
    namespaces = length(each.value.namespaces) > 0 ? each.value.namespaces : null
  }

  depends_on = [aws_eks_access_entry.cluster_access]
}

resource "aws_eks_access_policy_association" "app_deploy" {
  for_each = var.app_deploy_role_arns

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = [var.app_namespace]
  }

  depends_on = [aws_eks_access_entry.app_deploy]
}
