variable "repository_id" {
  type        = string
  description = "ID of the GitHub repository."
}

variable "build_environments" {
  type        = map(any)
  description = "List of build environments."
}
