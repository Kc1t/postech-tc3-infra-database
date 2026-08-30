variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "postech-tc3"
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "db_name" {
  type    = string
  default = "workshop"
}

variable "db_username" {
  type = string
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "allowed_cidr_blocks" {
  type    = list(string)
  default = ["10.0.0.0/8", "172.31.0.0/16"]
}
