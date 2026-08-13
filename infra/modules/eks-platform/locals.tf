data "aws_region" "current" {}

data "aws_partition" "current" {}

data "aws_availability_zones" "available" {
  state = "available"

  # Opt-in AZs (Local Zones, Wavelength) can't run EKS managed node groups.
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name = "${var.project}-${var.environment}"

  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  subnet_newbits = 4
  public_offset  = 8 # 2^subnet_newbits / 2, hence the az_count <= 8 validation

  private_subnets = { for i, az in local.azs : az => cidrsubnet(var.vpc_cidr, local.subnet_newbits, i) }
  public_subnets  = { for i, az in local.azs : az => cidrsubnet(var.vpc_cidr, local.subnet_newbits, i + local.public_offset) }

  nat_azs = var.single_nat_gateway ? slice(local.azs, 0, 1) : local.azs

  private_nat_az = { for az in local.azs : az => var.single_nat_gateway ? local.azs[0] : az }

  tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
