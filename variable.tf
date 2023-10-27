variable "vpc_cidr_block" {
    type = string
    default = "10.0.0.0/24"
    description = "Vpc cidr block"
}

variable "subnet_cidr_block" {
    type = list(string)
    default = ["10.0.0.0/28", "10.0.0.16/28"]
    description = "public subnet cidr blocks"
  
}

variable "availability_zone" {
    type = list(string)
    default = ["eu-west-2a", "eu-west-2b"]
    description = "availability zone"
  
}

variable "private_subnet_cidr_block" {
    type = list(string)
    default = ["10.0.0.32/28", "10.0.0.48/28"]
    description = "private subnet cidr blocks"
  
}

variable "private_availability_zone" {
    type = list(string)
    default = ["eu-west-2a", "eu-west-2b"]
    description = "private availability zone"
}


variable "public_subnet_name" {
    type = list(string)
    default = ["App1", "App2"]
    description = "public subnet names"
}


variable "private_subnet_name" {
    type = list(string)
    default = ["DB1", "DB2"]
    description = "private subnet names"
}


variable "public_subnets" {
    type = list(string)
    default = ["public_subnet1", "public_subnet2"]
    description = "tags for public subnets"
}

variable "private_subnets" {
    type = list(string)
    default = ["private_subnet1", "private_subnet2"]
    description = "tags for private subnets"
}

variable "public_route_table" {
    type = list(string)
    default = ["public_route_table1", "public_route_tabele2"]
    description = "public_route_table_names"

}

variable "private_route_table" {
    type = list(string)
    default = ["private_route_table1", "private_route_tabele2"]
    description = "private_route_table_names"

}



