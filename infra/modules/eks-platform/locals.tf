# Every resource is named "<project>-<environment>" (e.g. eks-multi-az-iac-poc-staging).
# Keeping the project prefix is what lets the scoped Terraform IAM policy
# (role/eks-multi-az-iac-poc-*) create this env's cluster and node roles.
locals {
  name = "${var.project}-${var.environment}"
}

# Region comes from the provider configured in the env root, read back for outputs.
data "aws_region" "current" {}
