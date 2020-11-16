# set up UniFi Controller

locals {
    public_key_path = "id_unifi.pub"
}

provider "aws" {
    profile = "unifi"
    region  = var.region
}

# look up user's default VPC
data "aws_vpc" "default" {
    default = true
}

# look up most recent Ubuntu 20.04 AMI
data "aws_ami" "ubuntu_ami" {
    most_recent = true
    owners      = ["099720109477"]

    filter {
        name   = "architecture"
        values = ["arm64"]
    }

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-arm64-server-*"]
    }

    filter {
        name   = "root-device-type"
        values = ["ebs"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

# firewall
resource "aws_security_group" "UniFi-Controller" {
    name        = "UniFi Controller"
    description = "Personal UniFi Controller"
    vpc_id      = data.aws_vpc.default.id

    ingress {
        description     = "STUN"
        from_port       = 3478
        to_port         = 3478
        protocol        = "udp"
        cidr_blocks     = var.site_cidr_blocks
    }

    ingress {
        description     = "UniFi Inform"
        from_port       = 8080
        to_port         = 8080
        protocol        = "tcp"
        cidr_blocks     = var.site_cidr_blocks
    }

    ingress {
        description     = "UniFi Captive Portal"
        from_port       = 8880
        to_port         = 8880
        protocol        = "tcp"
        cidr_blocks     = var.site_cidr_blocks
    }

    ingress {
        description     = "UniFi Captive Portal"
        from_port       = 8843
        to_port         = 8843
        protocol        = "tcp"
        cidr_blocks     = var.site_cidr_blocks
    }

    ingress {
        description     = "SSH"
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = flatten([var.management_cidr_blocks, var.site_cidr_blocks])
    }

    ingress {
        description     = "HTTPS, remap to 8443"
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        cidr_blocks     = flatten([var.management_cidr_blocks, var.site_cidr_blocks])
    }

    ingress {
        description     = "Management WebUI / API"
        from_port       = 8443
        to_port         = 8443
        protocol        = "tcp"
        cidr_blocks     = flatten([var.management_cidr_blocks, var.site_cidr_blocks])
    }

    ingress {
        description     = "ICMP"
        from_port       = -1
        to_port         = -1
        protocol        = "icmp"
        cidr_blocks     = flatten([var.management_cidr_blocks, var.site_cidr_blocks])
    }

    ingress {
        description     = "ACME HTTP-01 challenge"
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = {
        Name = "UniFi Controller"
        project = "unifi"
    }
}

resource "aws_key_pair" "UniFi-Controller" {
    key_name = "UniFi-Controller"
    public_key = file(local.public_key_path)
}

# ec2 vm
resource "aws_instance" "controller" {
    ami                         = data.aws_ami.ubuntu_ami.id
    ebs_optimized               = true
    instance_type               = "t4g.micro"
    monitoring                  = false
    key_name                    = "UniFi-Controller"
    vpc_security_group_ids      = [aws_security_group.UniFi-Controller.id]
    associate_public_ip_address = true
    source_dest_check           = true

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 30
        delete_on_termination = true
    }

    tags = {
        Name = "UniFi Controller"
        project = "unifi"
    }
}

resource "aws_eip" "controller-elastic-ip" {
    instance          = aws_instance.controller.id
    vpc               = true
}

output "public_dns" {
    value = var.hostname != "" ? var.hostname : aws_instance.controller.public_dns
}

output "public_ip" {
    value = aws_instance.controller.public_ip
}
