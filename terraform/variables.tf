variable "project_id" {
  description = "Unique project id for your Google Cloud project where resources will be created."
  type        = string
}

variable "customer_id" {
  description = "ID to be added to all resources that will be created."
  type        = string
}

variable "region" {
  description = "Region to be added to all resources that will be created."
  type        = string
}

variable "subnet" {
  description = "Region to be added to all resources that will be created."
  type        = string
}

variable "services" {
  description = "A list of Google Cloud services to enable."
  type        = list(string)
  default     = ["storage.googleapis.com", "eventarc.googleapis.com", "eventarcpublishing.googleapis.com", "workflows.googleapis.com", "workflowexecutions.googleapis.com", "compute.googleapis.com", "storage.googleapis.com", "transcoder.googleapis.com"]
}
