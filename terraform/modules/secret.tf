#creating a secret for an ingress resource 
resource "google_secret_manager_secret" "secret-basic" {
  secret_id = "myApiKey" #update this value in secretapp.yml

  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

#setting a value for secret in secrets manager
resource "google_secret_manager_secret_version" "secret-version-basic" {
  secret = google_secret_manager_secret.secret-basic.id

  secret_data = "281b5931-bf2f-4f36-9a88-3417469440a3"
}

