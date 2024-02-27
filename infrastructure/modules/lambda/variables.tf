variable "build_environments_names" {
  type        = set(string)
  description = "Set of names of the build environments."
}

variable "iam_role" {
  type        = string
  description = "ARN of the IAM lambda role."
}

variable "source_code_hash" {
  type        = string
  description = "Base64 SHA256 hash of the source code."
}

variable "output_path" {
  type        = string
  description = "Path to the output file."
}

variable "function_name" {
  type        = string
  description = "Name of the lambda@edge function."
}
