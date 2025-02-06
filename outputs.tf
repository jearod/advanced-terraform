output "subnet_gateway" {
  value = google_compute_subnetwork.subnet-1.gateway_address
}

output "nginx_public_ip" {
  value = google_compute_instance.nginx_instance.network_interface[0].access_config[0].nat_ip
  
}

# output "web1_private_ip" {
#   value = google_compute_instance.web1.network_interface[0].network_ip
# }

# output "web2_private_ip" {
#   value = google_compute_instance.web2.network_interface[0].network_ip
# }

# output "web3_private_ip" {
#   value = google_compute_instance.web3.network_interface[0].network_ip
# }

output "webserver_ips" {
  value = google_compute_instance.web-instances[*].network_interface[0].network_ip
}