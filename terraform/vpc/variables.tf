variable "vpc_cidr" {
   description = "CIDR block for vpc"
   default = "10.0.0.0/16"

}

variable "public_subnet_cidrs" {
    description = "Lists of CIDR blocks for public subnets"
    type = list(string)
    default = [ "10.0.0.0/24","10.0.2.0/24" ]
  
}

variable "private_subnet_cidrs" {
    description = "Lists of CIDR blocks for private subnets"
    type = list(string)
    default = [ "10.0.3.0/24","10.0.4.0/24" ]
  
}

variable "availability_zones" {
    description = "Lists of availability zones to use"
    type = list(string)
    default = [ "us-east-1a","us-east-1b" ]
  
}