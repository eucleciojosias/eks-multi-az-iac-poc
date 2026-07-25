# Supplied by CI as TF_VAR_* from the GitHub Environment's variables

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint. Lock to your IP/32. No default."
  type        = list(string)
  sensitive   = true

  validation {
    condition     = length(var.cluster_endpoint_public_access_cidrs) > 0
    error_message = "Provide at least one CIDR."
  }
}
