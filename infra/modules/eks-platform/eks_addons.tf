################################################################################
# Core add-ons — no IRSA role needed
################################################################################

data "aws_eks_addon_version" "core" {
  for_each = toset(["coredns", "kube-proxy", "vpc-cni"])

  addon_name         = each.key
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = true
}

resource "aws_eks_addon" "core" {
  for_each = data.aws_eks_addon_version.core

  cluster_name  = aws_eks_cluster.this.name
  addon_name    = each.key
  addon_version = each.value.version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = local.tags

  depends_on = [aws_eks_node_group.default]
}

################################################################################
# EBS CSI driver — needs an IRSA role, so it is wired up by hand
################################################################################

data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    sid     = "EbsCsiIrsa"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${local.name}-ebs-csi"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

data "aws_eks_addon_version" "ebs_csi" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = aws_eks_cluster.this.version
  most_recent        = true
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = data.aws_eks_addon_version.ebs_csi.version
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = local.tags

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi,
    aws_eks_node_group.default,
  ]
}
