variable "project_id" {
    type = string
    description = "GCP project id to be used"  
}

variable "region" {
  type = string
  description = "Location for GCP deployment"
  default = "us-central1"
}

variable "vpc_name" {
  type = string
}

variable "subnetwork_name" {
  type = string
}

variable "ip_cidr_range" {
  type = string
}

variable "gke_cluster_name" {
  type = string
}

variable "gke_master_zone" {
  type = string
  default = "us-central1-c" 
}

variable "gke_worker_zone" {
  type = string
  default = "us-central1-f" 
}

variable "machine_type" {
  type = string
}

