variable "untagged_image_expiry_days" {
  description = "Days before untagged images are expired."
  type        = number
  default     = 3
}

variable "max_image_count" {
  description = "Images kept per ECR repository; older ones are expired."
  type        = number
  default     = 3
}
