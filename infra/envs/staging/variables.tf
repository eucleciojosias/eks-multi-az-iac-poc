# Supplied by CI as TF_VAR_* from the GitHub Environment's variables

variable "app_deploy_role_arn" {
  description = "IAM role the app CD pipeline (app-ci.yml) assumes."
  type        = string
  default     = null
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint."
  type        = list(string)
  sensitive   = true

  validation {
    condition     = length(var.cluster_endpoint_public_access_cidrs) > 0
    error_message = "Provide at least one CIDR."
  }
}
