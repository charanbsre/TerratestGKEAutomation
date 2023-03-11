provider "google" {
  project = var.project_id
  region  = var.region
}

# https://www.terraform.io/language/settings/backends/gcs
terraform {
  backend "gcs" {
    bucket = "notfbackend"
    prefix = "terraform/state"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

module "dev_gke" {
  source        = "./modules"
  project_id    = var.project_id
  region        = var.region
  vpc_name      = var.vpc_name
  subnetwork_name = var.subnetwork_name
  ip_cidr_range = var.ip_cidr_range
  gke_cluster_name = var.gke_cluster_name
  gke_master_zone = var.gke_master_zone
  gke_worker_zone = var.gke_worker_zone
  machine_type = var.machine_type
}