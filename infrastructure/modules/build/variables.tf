variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "build_environments" {
  type = list(object({
    name      = string
    run_order = number
    branch    = string
  }))
  description = "Array of the build environments."
}

variable "build_environments_names" {
  type        = set(string)
  description = "Set of names of the build environments."
}

variable "repository_id" {
  type        = string
  description = "ID of the GitHub repository."
}
