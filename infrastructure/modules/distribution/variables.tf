variable "project_name" {
  type        = string
  description = "The name of the project."
}

variable "domain_name" {
  type        = string
  description = "The domain name of the website."
}

variable "build_environment" {
  type        = string
  description = "The website build environment the infrastructure is used for."
}
