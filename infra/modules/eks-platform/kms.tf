# Envelope-encrypts Kubernetes Secrets in etcd with a customer-managed key.
resource "aws_kms_key" "eks" {
  description             = "${local.name} EKS secrets envelope encryption"
  enable_key_rotation     = true
  deletion_window_in_days = var.kms_key_deletion_window_in_days

  tags = merge(local.tags, { Name = "${local.name}-eks" })
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${local.name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}
