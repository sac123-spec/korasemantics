variable "bucket_name" {
  description = "Name of the S3 bucket to create"
  type        = string
}

variable "force_destroy" {
  description = "Whether to force bucket destroy even if not empty"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable bucket versioning"
  type        = bool
  default     = true
}

variable "block_public_access" {
  description = "Block all public access to the bucket"
  type        = bool
  default     = true
}

variable "encryption_kms_key_id" {
  description = "KMS key ARN for default encryption. If null, S3 managed encryption is used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to bucket resources"
  type        = map(string)
  default     = {}
}

variable "lifecycle_rules" {
  description = "Lifecycle rules applied to the bucket"
  type = list(object({
    id                                     = string
    status                                 = string
    prefix                                 = optional(string)
    tags                                   = optional(map(string))
    transitions                            = optional(list(object({
      days          = optional(number)
      storage_class = string
    })))
    expiration                             = optional(object({
      days                         = optional(number)
      date                         = optional(string)
      expired_object_delete_marker = optional(bool)
    }))
    noncurrent_version_transitions          = optional(list(object({
      newer_noncurrent_versions = optional(number)
      noncurrent_days           = optional(number)
      storage_class             = string
    })))
    noncurrent_version_expiration           = optional(object({
      newer_noncurrent_versions = optional(number)
      noncurrent_days           = optional(number)
    }))
    abort_incomplete_multipart_upload_days = optional(number)
  }))
  default = []
}
