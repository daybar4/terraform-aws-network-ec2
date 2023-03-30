# -----------------------------------------------
# START OF network section
# -----------------------------------------------

/*
* Create VPC
* VPC with CIDR 172.16.0.0/16
*/
resource "aws_vpc" "vpc" {           ## In all blocks, first the target resource in aws, second the ID for this file to call it
  cidr_block       = "172.16.0.0/16" ## 172.16.0.0/16 - /16 means the first two bytes (172.16.) are network.
  instance_tenancy = "default"

  tags = {
    Name = "aws-vpc-prod"
  }
}

/*
* Create internet gateway
*/
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "aws-ig-prod"
  }
}

/*
* Create public subnets
*/
resource "aws_subnet" "aws-public-prod_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "172.16.1.0/24" ## Subnet lower than VPC, in range between (.0.0/16)
  availability_zone       = var.aws_zone["ireland.a"]
  map_public_ip_on_launch = true

  tags = {
    Name = "aws-public-prod_1"
  }
}

/*
* Create private subnets
*/
resource "aws_subnet" "aws-private-prod_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "172.16.3.0/24" ## Subnet lower than VPC, in range between (.0.0/16)
  availability_zone       = var.aws_zone["ireland.a"]
  map_public_ip_on_launch = false

  tags = {
    Name = "aws-private-prod_1"
  }
}

/*
* Create route table to internet gateway
*/
resource "aws_route_table" "aws-prod-rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig.id
  }
  tags = {
    Name = "aws-prod-rt"
  }
}

/*
* Associate public subnets with route table
*/
resource "aws_route_table_association" "aws-public-route_1" {
  subnet_id      = aws_subnet.aws-public-prod_1.id
  route_table_id = aws_route_table.aws-prod-rt.id
}

/*
* Create security groups
*/
resource "aws_security_group" "aws-prod-public_sg" {
  name        = "aws-prod-public_sg"
  description = "Allow public traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH standard"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "outbound traffic open"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

resource "aws_security_group" "aws-prod-private_sg" {
  name        = "aws-prod-private_sg"
  description = "Allow private traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "SSH standard"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}

# -----------------------------------------------
# END OF network section
# -----------------------------------------------

# -----------------------------------------------
# START OF instances & provisioning section
# -----------------------------------------------

/*
* Create ec2 instances
*/
resource "aws_instance" "instance" {
  depends_on                  = [aws_security_group.aws-prod-public_sg, aws_subnet.aws-public-prod_1]
  ami                         = var.aws_ami["ireland.debian11"]
  instance_type               = var.aws_instance["2"]
  key_name                    = var.private_key_name
  availability_zone           = var.aws_zone["ireland.a"]
  vpc_security_group_ids      = [aws_security_group.aws-prod-public_sg.id]
  subnet_id                   = aws_subnet.aws-public-prod_1.id
  associate_public_ip_address = true
  root_block_device {
    volume_type               = "gp2"
    volume_size               = "10" # IN GB
    delete_on_termination     = true ## Change to false if you want to keep it.
  }

  tags = {
    Name = "new-instance-prod" ## <<<<<<<<<<<< CHANGE NAME
  }
}

/*
* Create a disk
*/
resource "aws_ebs_volume" "data" {
  availability_zone = var.aws_zone["ireland.a"]
  size              = 40 # IN GB

  tags = {
    Name = "new-instance-data" ## <<<<<<<<<<<< CHANGE NAME
  }
}

/*
* Attach extra disk to server
*/
resource "aws_volume_attachment" "ebs_attachment" {
  depends_on      = [aws_ebs_volume.data]
  device_name     = var.ebs_attachment_name
  volume_id       = aws_ebs_volume.data.id
  instance_id     = aws_instance.instance.id
  force_detach    = true
}

/*
* Null (false) resource: remote executions scripts must be run after attaching data disk
*/
resource "null_resource" "provisioning-to-ec2" {
  depends_on = [aws_volume_attachment.ebs_attachment]

  provisioner "remote-exec" {
    inline = ["sudo hostnamectl set-hostname new-instance-prod && echo '127.0.0.1 new-instance-prod' | sudo tee --append /etc/hosts > /dev/null"] ## <<<<<<<<<<<< CHANGE NAME
  }

  provisioner "file" { ## Each argument may be set only once.
    source      = "./deploy/scripts/mount-disk.sh"
    destination = "/tmp/mount-disk.sh"
    #on_failure = "continue"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/mount-disk.sh",
      "sudo bash /tmp/mount-disk.sh",
      ## "sudo -H -u root bash -c 'bash /tmp/script.sh'" ## Need to pass the execution to user root ?
    ]
  }

  /*
  * Login to the ec2-user with the aws key.
  */
  connection {
    type        = "ssh"
    host        = aws_instance.instance.public_ip
    user        = var.aws_instance_username
    private_key = file(var.private_key_path)  ## <<<<<< PUT YOUR OWN PRIVATE KEY FILE
    timeout     = "2m"
  }
}

# -----------------------------------------------
# END OF instances & provisioning section
# -----------------------------------------------

# -----------------------------------------------
# START OF DNS Cloudflare section
# -----------------------------------------------

/*
 * Declare domain zone
 */
data "cloudflare_zone" "domain" {
  name = "domain.com"  ## <<<<<<<<<<<< YOUR DOMAIN HERE
}

/*
 * Create Cloudflare DNS record
 */
resource "cloudflare_record" "webdns" {
 zone_id  = data.cloudflare_zone.domain.id
 name    = "www" ## <<<<<<<<<<<< CHANGE DNS RULE VALUE, put @ for default
 value   = aws_instance.instance.public_ip
 type    = "A"
 proxied = true
}

# -----------------------------------------------
# END OF DNS Cloudflare section
# -----------------------------------------------