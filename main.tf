provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "vpn_server_key" {
  key_name   = "vpn_server_ssh_key"
  public_key = file("./ssh_keys/aws_vpn_key.pub")
}

resource "aws_default_vpc" "default" {}

resource "aws_security_group" "vpn_server_sg" {
  name   = "vpn_instance-security-group"
  vpc_id = aws_default_vpc.default.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["193.56.243.91/32"]
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
    Name                      = "vpn_server"
  }
}

resource "aws_instance" "vpn_instance" {
  vpc_id = aws_default_vpc.default.id
  ami                         = "ami-0885b1f6bd170450c"
  key_name                    = aws_key_pair.vpn_server_key.key_name
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.vpn_server_sg.name]
  associate_public_ip_address = true
    tags = {
    Name                      = "vpn_server"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    password    = ""
  }
}

resource "aws_eip" "vpn_elastic_ip" {
  instance = aws_instance.vpn_instance.id
  vpc      = true
  tags = {
    Name = "eip-vpn_instance"
  }
}

resource "null_resource" "ansible-provision" {

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
