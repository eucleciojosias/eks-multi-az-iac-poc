################################################################################
# Cluster role — assumed by the EKS control plane
################################################################################

data "aws_iam_policy_document" "cluster_assume_role" {
  statement {
    sid = "EKSClusterAssumeRole"

    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name                  = "${local.name}-cluster"
  assume_role_policy    = data.aws_iam_policy_document.cluster_assume_role.json
  force_detach_policies = true

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  for_each = toset([
    "AmazonEKSClusterPolicy",
    "AmazonEKSVPCResourceController",
  ])

  role       = aws_iam_role.cluster.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/${each.value}"
}

data "aws_iam_policy_document" "cluster_encryption" {
  statement {
    sid    = "SecretsEnvelopeEncryption"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ListGrants",
      "kms:DescribeKey",
    ]

    resources = [aws_kms_key.eks.arn]
  }

  statement {
    sid       = "GrantToEksService"
    effect    = "Allow"
    actions   = ["kms:CreateGrant"]
    resources = [aws_kms_key.eks.arn]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role_policy" "cluster_encryption" {
  name   = "${local.name}-cluster-encryption"
  role   = aws_iam_role.cluster.id
  policy = data.aws_iam_policy_document.cluster_encryption.json
}

################################################################################
# Node role — assumed by the EC2 instances in the managed node group
################################################################################

data "aws_iam_policy_document" "node_assume_role" {
  statement {
    sid     = "EKSNodeAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "node" {
  name                  = "${local.name}-node"
  assume_role_policy    = data.aws_iam_policy_document.node_assume_role.json
  force_detach_policies = true

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "node" {
  for_each = toset([
    "AmazonEKSWorkerNodePolicy",
    "AmazonEC2ContainerRegistryReadOnly",
    "AmazonEKS_CNI_Policy",
  ])

  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/${each.value}"
}
