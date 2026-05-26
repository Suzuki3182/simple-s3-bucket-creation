variable "bucket_name" {
  description = "The name of the S3 bucket. Must be globally unique."
  type        = string
}

variable "read_only_iam_user_arn" {
  description = "The ARN of the IAM user to grant read-only access to the S3 bucket."
  type        = string
}

variable "force_destroy" {
  description = "Whether to allow the bucket to be destroyed even if it contains objects."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}
