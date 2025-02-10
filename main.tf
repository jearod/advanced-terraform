### PROVIDER
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

### NETWORK
data "google_compute_network" "default" {
  name = "default"
}

## SUBNET
resource "google_compute_subnetwork" "subnet-1" {
  name                     = var.subnet-name
  ip_cidr_range            = var.subnet-cidr
  network                  = data.google_compute_network.default.self_link
  region                   = var.region
  private_ip_google_access = var.private_google_access
}

resource "google_compute_firewall" "default" {
  name    = "ingress-firewall"
  network = data.google_compute_network.default.self_link

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = var.firewall-ports
  }

  source_tags = var.compute-source-tags
}

module "firewall_rules" {
  source       = "terraform-google-modules/network/google//modules/firewall-rules"
  project_id   = var.project_id
  network_name = data.google_compute_network.default.self_link

  rules = [{
    name               = "allow-all-egress"
    direction          = "EGRESS"      
    destination_ranges = ["0.0.0.0/0"]    
    

    allow = [{
      protocol = "tcp"
      ports    = ["0-65535"]
    }]
    
  }]
}

### COMPUTE
## NGINX PROXY
resource "google_compute_instance" "nginx_instance" {
  name         = "nginx-proxy"
  machine_type = var.environment_machine_type[var.target_environment]
  tags = var.compute-source-tags

  labels = {
    environment = var.environment_map[var.target_environment]
  }

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
    }
  }

  network_interface {
    network = data.google_compute_network.default.self_link
    subnetwork = google_compute_subnetwork.subnet-1.self_link
    access_config {
  
    }
  }
}

## BUCKETS
resource "google_storage_bucket" "environment_buckets" {
  for_each = toset(var.environment_list)
  name = "${lower(each.key)}_bucket_jearod"
  location = "US"
  versioning {
    enabled = true
  }
}
## WEB-INSTANCES
resource "google_compute_instance" "web-instances" {
  count        = 2
  name         = "web${count.index + 1}"
  machine_type = var.environment_machine_type[var.target_environment]
 
  labels = {
    environment = var.environment_map[var.target_environment]
  }

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = data.google_compute_network.default.self_link
    subnetwork = google_compute_subnetwork.subnet-1.self_link
  }
}

## WEBSERVERS-MAP
resource "google_compute_instance" "web-map-intances" {
  for_each     = var.environment_instance_settings
  name         = "web-${lower(each.key)}"
  machine_type = each.value.machine_type
  labels       = each.value.labels

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
    }
  }

  network_interface {
    network = data.google_compute_network.default.self_link
    subnetwork = google_compute_subnetwork.subnet-1.self_link
  }
}

## DB
resource "google_compute_instance" "mysqldb" {
  name         = "mysqldb"
  machine_type = var.environment_machine_type[var.target_environment]
  
  labels = {
    environment = var.environment_map[var.target_environment]
  }

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
    }
  }

  network_interface {
    network = data.google_compute_network.default.self_link
    subnetwork = google_compute_subnetwork.subnet-1.self_link
  }  
}

# resource "random_id" "db_name_suffix" {
#   byte_length = 4
# }

# ## CLOUD SQL
# resource "google_sql_database_instance" "cloudsql" {
#   name             = "web-app-db-${random_id.db_name_suffix.hex}"
#   database_version = "MYSQL_8_0"
#   region           = "us-central1"

#   settings {
#     tier = "db-e2-micro"
#   }
#   deletion_protection = false
# }

# ## CLOUD SQL USER
# resource "google_sql_user" "users" {
#   name     = var.dbusername
#   instance = google_sql_database_instance.cloudsql.name
#   password = var.dbpassword
# }