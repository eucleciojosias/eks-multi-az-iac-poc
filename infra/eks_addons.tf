# IRSA role for the EBS CSI driver — lets the controller pods manage EBS volumes
# via a scoped IAM role (no static keys). Role name is project-prefixed so the
# scoped Terraform IAM policy permits it.
module "ebs_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-ebs-csi"

  # Attach the AWS-managed policy directly rather than attach_ebs_csi_policy,
  # which would create a customer policy named "AmazonEKS_EBS_CSI_Policy-*" —
  # that name doesn't match the scoped Terraform IAM policy's project prefix, so
  # iam:CreatePolicy would be denied. Attaching the managed ARN needs only
  # AttachRolePolicy on the (prefixed) role, which is already allowed.
  role_policy_arns = {
    ebs_csi = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = { Project = var.project }
}

# EBS CSI driver as a managed add-on. Kept OUT of the eks module's cluster_addons
# to avoid a cycle: the IRSA role depends on the module's OIDC output, and this
# add-on depends on the IRSA role.
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = module.ebs_csi_irsa.iam_role_arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = { Project = var.project }
}
