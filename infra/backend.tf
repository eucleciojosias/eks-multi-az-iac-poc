terraform {
  backend "s3" {
    bucket       = "eks-multi-az-iac-poc-tfstate"
    key          = "eks-multi-az-iac-poc/infra.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
