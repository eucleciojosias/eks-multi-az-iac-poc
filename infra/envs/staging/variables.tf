# Supplied by CI as TF_VAR_* from the GitHub Environment's variables

variable "app_deploy_role_arn" {
  description = "IAM role the app CD pipeline (app-ci.yml) assumes."
  type        = string
  default     = null
}

variable "tf_apply_role_arn" {
  description = "IAM role iac-ci.yml applies with. Gets cluster-admin so it can manage the ingress-nginx release. Leave unset if CI created the cluster — it is already admin, and a second access entry for the same principal errors."
  type        = string
  default     = null
}

variable "tf_plan_role_arn" {
  description = "IAM role tf-plan.yml plans with. Gets read-including-Secrets so refreshing the Helm release state works without any write access."
  type        = string
  default     = null
}

variable "local_admin_principal_arn" {
  description = "Your own IAM user/role, for applying from a laptop against a cluster CI created. Leave unset when you created the cluster yourself — same collision as tf_apply_role_arn."
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
