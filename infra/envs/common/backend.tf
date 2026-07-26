terraform {
  backend "s3" {
    bucket       = "eks-multi-az-iac-poc-tfstate"
    key          = "common/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
