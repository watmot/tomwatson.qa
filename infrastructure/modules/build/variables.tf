variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "build_environments" {
  type        = map(any)
  description = "Array of the build environments."
}

variable "repository_id" {
  type        = string
  description = "ID of the GitHub repository."
}
