output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "secretapp_fqdn" {
  value = google_dns_record_set.secretapp.name
}

output "helloapp_fqdn" {
  value = google_dns_record_set.helloapp.name
}