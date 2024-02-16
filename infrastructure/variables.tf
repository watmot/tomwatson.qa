variable "repository_id" {
  type        = string
  description = "ID of the GitHub repository."
}

variable "build_environments" {
  type = list(object({
    name      = string
    run_order = number
    branch    = string
  }))
  description = "List of build environments."
}
