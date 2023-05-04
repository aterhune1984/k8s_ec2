
variable "AWS_REGION" {
	default = "us-east-2"
}

# If you are using different region (other than us-east-1) please find ubuntu 18.04 ami for that region and change here.
variable "ami_id" {
    type = string
    default = "ami-0a695f0d95cefc163"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "vpc_cidr" {
    type = string
    default = "10.1.0.0/16"
}

variable "private_subnets" {
    type = list(string)
    default = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "public_subnets" {
    type = list(string)
    default = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
}

variable "master_node_count" {
    type = number
    default = 3
}

variable "worker_node_count" {
    type = number
    default = 3
}

variable "ssh_user" {
    type = string
    default = "ubuntu"
}

variable "master_instance_type" {
    type = string
    default = "t3.micro"
}

variable "worker_instance_type" {
    type = string
    default = "t2.micro"
}