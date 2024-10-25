variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}
# Additional KV store specific ports
variable "kvstore_client_port" {
  description = "Port for KV store client connections"
  type        = number
  default     = 8080
}

variable "kvstore_peer_port" {
  description = "Port for KV store peer communication"
  type        = number
  default     = 7946
}

variable "kvstore_gossip_port" {
  description = "Port for gossip protocol"
  type        = number
  default     = 7947
}