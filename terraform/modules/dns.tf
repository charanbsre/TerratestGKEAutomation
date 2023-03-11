#Creating public dns record for ingress resource
resource "google_dns_record_set" "secretapp" {
  name         = "secretapp.${google_dns_managed_zone.nextopszone.dns_name}"
  managed_zone = google_dns_managed_zone.nextopszone.name
  type         = "A"
  ttl          = 300

  rrdatas = ["${google_compute_global_address.default.address}"]
}

#Creating public dns record for ingress resource
resource "google_dns_record_set" "helloapp" {
  name         = "helloapp.${google_dns_managed_zone.nextopszone.dns_name}"
  managed_zone = google_dns_managed_zone.nextopszone.name
  type         = "A"
  ttl          = 300

  rrdatas = ["${google_compute_global_address.default.address}"]
}

#Creating public dns zone for ingress resource
resource "google_dns_managed_zone" "nextopszone" {
  name     = "nextopsvideos"
  dns_name = "nextopsvideos.com."
}

#Executing ingress deletion during destroy
resource "null_resource" "ingress" {
    provisioner "local-exec" {
      when = destroy
      command     = "kubectl delete ing ingress"
    }
}
