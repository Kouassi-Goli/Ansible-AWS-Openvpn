variable "ip_address" {
  type = string
  description = "The ip address for ssh security group"
}

variable "project_name" {
  type = string
  description = "The name of the project or server"
  default = "vpn"
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "vpn_key" {
  key_name   = var.project_name
  public_key = file("./ssh_keys/aws_vpn_key.pub")
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name                       = var.project_name
  }

}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name                       = var.project_name
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name                      = var.project_name
  }
}

resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name                      = var.project_name
  }
}

resource "aws_route_table_association" "rtba" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.rtb.id

}

resource "aws_security_group" "vpn_sg" {
  name   = "vpn_security_group"
  vpc_id = aws_vpc.vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.ip_address]
  }
# OpenVPN
  ingress {
    protocol    = "udp"
    from_port   = 1194
    to_port     = 1194
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name                      = var.project_name
  }
}

resource "aws_instance" "vpn_instance" {
  ami                         = "ami-042e8287309f5df03"
  key_name                    = aws_key_pair.vpn_key.key_name
  subnet_id                   = aws_subnet.subnet.id
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.vpn_sg.id]
  associate_public_ip_address = true
    tags = {
    Name                      = var.project_name
  }
}


resource "aws_eip" "vpn_elastic_ip" {
  instance = aws_instance.vpn_instance.id
  vpc      = true
  tags = {
    Name = "eip-vpn_instance"
  }
}

resource "null_resource" "ansible_provision" {

  depends_on = [aws_instance.vpn_instance, aws_eip.vpn_elastic_ip]
  ##Create inventory
  provisioner "local-exec" {
    command = "echo \"[servers]\" > ./hosts"
  }
  provisioner "local-exec" {
    command = "echo \"${format("%s ansible_host=%s ansible_user=ubuntu", aws_instance.vpn_instance.tags.Name, aws_eip.vpn_elastic_ip.public_ip)}\" >> ./hosts"
  }

  provisioner "local-exec" {
    command = "echo \"\n[all:vars]\nansible_python_interpreter=/usr/bin/python3\" >> ./hosts"
  }
}

output "vpn_server_public_ip" {
  description = "The public elastic ip for ssh access"
  value = aws_eip.vpn_elastic_ip.public_ip
}
