variable "project_id" {
  description = "Unique project id for your Google Cloud project where resources will be created."
  type        = string
}

variable "customer_id" {
  description = "ID to be added to all resources that will be created."
  type        = string
  default     = "gcp"
}

variable "region" {
  description = "Region to be added to all resources that will be created."
  type        = string
  default     = "us-central1"
}

variable "subnet" {
  description = "Subnet IP address range for VPC."
  type        = string
  default     = "10.128.0.0/20"
}

variable "job_namespace" {
  description = "GKE namespace for jobs, for WI configuration"
  type        = string
  default     = "jobs"
}
