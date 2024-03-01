variable "project_name" {
  type        = string
  description = "Name of the project."
}

variable "build_environment" {
  type        = string
  description = "Name of the build environment."
}

variable "basic_auth_enabled" {
  type        = bool
  description = "Boolean to determine whether basic auth should be enabled for the environment."
}

variable "function_name" {
  type        = string
  description = "Name of the lambda@edge function."
}
