# Same tag keys as the env roots so cost allocation groups cleanly; "common"
# marks the resources that outlive any single environment.
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "eks-multi-az-iac-poc"
      Environment = "common"
      ManagedBy   = "terraform"
    }
  }
}
