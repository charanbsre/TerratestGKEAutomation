# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account
resource "google_service_account" "kubernetes" {
  account_id = "kubernetes"
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster
resource "google_container_cluster" "primary" {
  name                     = var.gke_cluster_name #"nextopsgke02"
  location                 = var.gke_master_zone 
  remove_default_node_pool = false
  initial_node_count       = 2
  network                  = google_compute_network.vpc.self_link
  subnetwork               = google_compute_subnetwork.subnet.self_link
  logging_service          = "logging.googleapis.com/kubernetes"
  monitoring_service       = "monitoring.googleapis.com/kubernetes"
  networking_mode          = "VPC_NATIVE"

  # Optional, if you want multi-zonal cluster
  node_locations = [
    var.gke_worker_zone
  ]

  node_config {
    preemptible  = false
    machine_type = var.machine_type #e2-medium
    disk_size_gb = 75
    disk_type = "pd-standard"

    labels = {
      role = "general"
    }

    service_account = google_service_account.kubernetes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "k8s-pod-range"
    services_secondary_range_name = "k8s-service-range"
  }

  private_cluster_config {
    enable_private_nodes    = false
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }
}


# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account
resource "google_service_account" "secret-ro-sa" {
  account_id = "secret-ro-sa" 
  #update secretapp.yml and serviceaccount.yml with correct sa name if you change this value
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_project_iam
resource "google_project_iam_member" "secret-ro-sa" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.secret-ro-sa.email}"
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/google_service_account_iam
resource "google_service_account_iam_member" "secret-ro-sa" {
  service_account_id = google_service_account.secret-ro-sa.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/secret-ro-sa]"
}

# resource to fetch kubeconfig from GKE cluster dynamically
resource "null_resource" "local" {
    depends_on = [
      google_container_cluster.primary
    ]
    provisioner "local-exec" {
      command = "gcloud container clusters get-credentials ${var.gke_cluster_name} --zone us-central1-c --project protean-beaker-376112"
    }
}

# Delay for successful cleanup 
resource "time_sleep" "wait_4_min" {
  depends_on = [google_container_cluster.primary]
  destroy_duration = "240s"
}