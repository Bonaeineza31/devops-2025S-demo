terraform {
  cloud {
    organization = "alu-devops-bonaeineza"
    workspaces {
      name = "campus-notifier-infra"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "alu-devops-key"
  public_key = file(pathexpand(var.public_key_path))
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# App Security Group
resource "aws_security_group" "app" {
  name        = "campus-notifier-app-sg"
  description = "Security group for campus-notifier app instance"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description = "App port"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #checkov:skip=CKV_AWS_382:Accepted risk - host needs outbound internet for apt, Docker Hub and image pulls; lab box has no NAT/proxy
  egress {
    description      = "All outbound (apt, Docker pulls)"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "campus-notifier-app-sg"
  }
}

# DB Security Group
resource "aws_security_group" "db" {
  name        = "campus-notifier-db-sg"
  description = "Security group for campus-notifier database instance"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description     = "PostgreSQL from App Server"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  #checkov:skip=CKV_AWS_382:Accepted risk - host needs outbound internet for apt, Docker Hub and image pulls; lab box has no NAT/proxy
  egress {
    description      = "All outbound (apt, Docker pulls)"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "campus-notifier-db-sg"
  }
}

# Ubuntu 24.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# App Instance
resource "aws_instance" "app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true
  ebs_optimized               = true

  #checkov:skip=CKV_AWS_88:Accepted risk - public IP needed so Ansible/SSH from the laptop and users can reach the app; SSH limited to my_ip_cidr
  #checkov:skip=CKV_AWS_126:Accepted risk - detailed monitoring costs extra; short-lived lab instance, destroyed after class
  #checkov:skip=CKV2_AWS_41:Accepted risk - instance makes no AWS API calls, so no IAM role is needed

  metadata_options {
    http_tokens   = "required" # IMDSv2 only
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "campus-notifier-app"
  }
}

# DB Instance
resource "aws_instance" "db" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.db.id]
  associate_public_ip_address = true
  ebs_optimized               = true

  #checkov:skip=CKV_AWS_88:Accepted risk - public IP needed for Ansible over SSH (no bastion in lab); SSH limited to my_ip_cidr, Postgres only from app SG
  #checkov:skip=CKV_AWS_126:Accepted risk - detailed monitoring costs extra; short-lived lab instance, destroyed after class
  #checkov:skip=CKV2_AWS_41:Accepted risk - instance makes no AWS API calls, so no IAM role is needed

  metadata_options {
    http_tokens   = "required" # IMDSv2 only
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    Name = "campus-notifier-db"
  }
}

