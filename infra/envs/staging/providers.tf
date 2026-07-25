# The env root is the ONLY place a provider is configured; the module inherits it.
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "eks-multi-az-iac-poc"
      Environment = "staging"
      ManagedBy   = "terraform"
    }
  }
}
