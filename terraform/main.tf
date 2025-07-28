terraform {
  required_version = ">= 1.0"
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

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC
resource "aws_vpc" "payment_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "payment-system-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "payment_igw" {
  vpc_id = aws_vpc.payment_vpc.id

  tags = {
    Name = "payment-system-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.payment_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "payment-system-public-subnet"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.payment_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.payment_igw.id
  }

  tags = {
    Name = "payment-system-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "payment_sg" {
  name_prefix = "payment-system-"
  vpc_id      = aws_vpc.payment_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Gateway Service
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RabbitMQ Management (optional, restrict as needed)
  ingress {
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = var.allowed_management_cidr
  }

  # Monitoring (optional)
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_management_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "payment-system-sg"
  }
}

# Key Pair
resource "aws_key_pair" "payment_key" {
  key_name   = "payment-system-key"
  public_key = var.public_key

  tags = {
    Name = "payment-system-key"
  }
}

# EC2 Instance
resource "aws_instance" "payment_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.payment_key.key_name
  vpc_security_group_ids = [aws_security_group.payment_sg.id]
  subnet_id              = aws_subnet.public.id

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    git_repo = var.git_repository
  }))

  tags = {
    Name = "payment-system-server"
    Type = "production"
  }
}

# Elastic IP
resource "aws_eip" "payment_eip" {
  instance = aws_instance.payment_server.id
  domain   = "vpc"

  tags = {
    Name = "payment-system-eip"
  }
}

# Application Load Balancer (optional, for high availability)
resource "aws_lb" "payment_alb" {
  count              = var.enable_load_balancer ? 1 : 0
  name               = "payment-system-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.payment_sg.id]
  subnets            = [aws_subnet.public.id]

  enable_deletion_protection = false

  tags = {
    Name = "payment-system-alb"
  }
}

resource "aws_lb_target_group" "payment_tg" {
  count    = var.enable_load_balancer ? 1 : 0
  name     = "payment-system-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.payment_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/api/v1/gateway/health"
    matcher             = "200"
  }

  tags = {
    Name = "payment-system-tg"
  }
}

resource "aws_lb_listener" "payment_listener" {
  count             = var.enable_load_balancer ? 1 : 0
  load_balancer_arn = aws_lb.payment_alb[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payment_tg[0].arn
  }
}

resource "aws_lb_target_group_attachment" "payment_tg_attachment" {
  count            = var.enable_load_balancer ? 1 : 0
  target_group_arn = aws_lb_target_group.payment_tg[0].arn
  target_id        = aws_instance.payment_server.id
  port             = 80
} 