output "cluster_name" {
  value = module.dev_gke.cluster_name
}

output "secretapp_fqdn" {
  value = module.dev_gke.secretapp_fqdn
}

output "helloapp_fqdn" {
  value = module.dev_gke.helloapp_fqdn
}