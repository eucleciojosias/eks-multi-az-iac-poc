variable "untagged_image_expiry_days" {
  description = "Days before untagged images are expired. Untagged means superseded by a newer push."
  type        = number
  default     = 3
}
