locals {
  region = "us-east-1"
}

# The env root is the ONLY place a provider is configured; the module inherits it.
provider "aws" {
  region = local.region

  default_tags {
    tags = {
      Project     = "eks-multi-az-iac-poc"
      Environment = "staging"
      ManagedBy   = "terraform"
    }
  }
}

# Token over exec rather than a static one: `aws eks get-token` runs at apply
# time, so the 15-minute credential can't go stale between plan and apply.
provider "helm" {
  kubernetes {
    host                   = module.platform.cluster_endpoint
    cluster_ca_certificate = base64decode(module.platform.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.platform.cluster_name, "--region", local.region]
    }
  }
}
