################
### KEYS SECTION 
################

/*
* To log in to AWS account. Secret values
*/
#variable "access_key" {}
#variable "secret_key" {}

variable "access_key" {
  description = "ID acces KEY"
  default     = "XXXXXXXXXXXXXXXXXXX"
}

variable "secret_key" {
  description = "Value secret KEY"
  default     = "XXXXXXXXXXXXXXXXXXXX"
}

/*
* To log in to cloudflare account
*/
variable "cloudflare_api_token" {
  description = "cloudflare api token"
  default       = "XXXXXXXXXXXXXXXXXXXX"
}

/*
* To ssh into the AWS instance
*/
variable "aws_instance_username" {  ## default username for debian EC2
  description = "User for connect with ssh"
  default     = "admin"
}

variable "private_key_name" {
  description = "Private Key name for assign to ec2 instance"
  default     = "terraform-prod-keypair"
}

variable "private_key_path" {
  description = "Private Key path to connect via ssh"
  default     = "ssh-keys/terraform-prod-keypair"
}

#######################
### END OF KEYS SECTION
#######################

##########################
### START OF AWS Variables
##########################

variable "aws_zone" {
  type = map
  default = {
    "frankfurt" = "eu-central-1"
    "frankfurt.a" = "eu-central-1a"
    "frankfurt.b" = "eu-central-1b"
    "frankfurt.c" = "eu-central-1c"
    "ireland" = "eu-west-1"
    "ireland.a" = "eu-west-1a"
    "ireland.b" = "eu-west-1b"
    "ireland.c" = "eu-west-1c"
  }
}

variable "aws_ami" { ## 64 bits
  type = map
  default = {
    "ireland.debian11" = "ami-089f338f3a2e69431"
    "ireland.amazon-linux"  = "ami-0779c326801d5a843"
    "ireland.ubuntu22"  = "ami-06d94a781b544c133"
    "ireland.redhat9" = "ami-0f7358877f243c5c7"
    "frankfurt.debian11" = "ami-08f13e5792295e1b2"
    "frankfurt.amazon-linux"  = "ami-0499632f10efc5a62"
    "frankfurt.ubuntu22"  = "ami-0d1ddd83282187d18"
    "frankfurt.redhat9" = "ami-03f255060aa887525"
  }
}

variable "aws_instance" {
  type        = map
  description = "EC2 nodes instances type"
  default     = {
    "0"       = "t1.micro"
    "1"       = "t2.micro"
    "2"       = "t3.medium"
    "3"       = "t3.large"
    "4"       = "t3.xlarge"
    "5"       = "t3.2xlarge"
  }
  # t1.micro 1 vCPU + 0,613 Memoria (GiB) 64 bits   = 0
  # t2.micro 1 vCPU + 1 Memoria (GiB) 64 bits       = 1
  # t3.medium 2 vCPU + 4 Memoria (GiB) 64 bits      = 2
  # t3.large 2 vCPU + 8 Memoria (GiB) 64 bits       = 3
  # t3.xlarge 4 vCPU + 16 Memoria (GiB) 64 bits     = 4
  # t3.2xlarge 8 vCPU + 32 Memoria (GiB) 64 bits    = 5
}

variable "ebs_attachment_name" {
  description = "Volum name"
  default     = "/dev/xvdh"
}

########################
### END OF AWS Variables
########################