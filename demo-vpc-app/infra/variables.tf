variable "access_key" {
  type      = string
  sensitive = true
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "organization_id" {
  type      = string
  sensitive = true
}

variable "project_id" {
  type      = string
  sensitive = true
}

variable "zone" {
  type    = string
  default = "fr-par-1"
}

variable "region" {
  type    = string
  default = "fr-par"
}

variable "app_name" {
  type        = string
  description = "Name of the App"
  default     = "task-tracker"
}

variable "instances_count" {
  description = "The number of Instances"
  type        = number
  default     = 1
}
