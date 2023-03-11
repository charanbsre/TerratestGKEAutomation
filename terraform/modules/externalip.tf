#Reserving a public ip for gke ingress controller
resource "google_compute_global_address" "default" {
  project      = var.project_id # Replace this with your service project ID in quotes
  name         = "ingress-webapp01"
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

