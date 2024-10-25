
# terraform.tfvars
aws_region     = "us-east-1"
environment    = "dev"          # Change this for different environments (dev/staging/prod)
project_name   = "kvstore"

# VPC Configuration
vpc_cidr = "10.0.0.0/16"

# Availability Zones for us-east-1
availability_zones = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c"
]

# Subnet CIDR blocks
private_subnet_cidrs = [
  "10.0.0.0/19",   # us-east-1a private
  "10.0.32.0/19",  # us-east-1b private
  "10.0.64.0/19"   # us-east-1c private
]

public_subnet_cidrs = [
  "10.0.96.0/19",   # us-east-1a public
  "10.0.128.0/19",  # us-east-1b public
  "10.0.160.0/19"   # us-east-1c public
]

# Default tags for all resources
default_tags = {
  Environment = "dev"
  Project     = "kvstore"
  ManagedBy   = "terraform"
  Region      = "us-east-1"
  Owner       = "infrastructure-team"
  CreatedBy   = "terraform"
}
kvstore_client_port = 8080
kvstore_peer_port   = 7946
kvstore_gossip_port = 7947
create_https_listener = false  # Set to true if you want HTTPS
