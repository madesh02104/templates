# =============================================================================
# TERRAFORM AWS INFRASTRUCTURE TEMPLATE
# Provisions: EC2 Instance + Security Group + Key Pair + S3 Bucket
# OS: Ubuntu 22.04 LTS
# Pre-installed on EC2: Docker + Docker Compose
#
# HOW TO USE:
#   1. Copy this entire folder into your project as /terraform
#   2. Fill in terraform.tfvars with your values
#   3. Run: terraform init
#   4. Run: terraform plan     (preview - nothing created yet)
#   5. Run: terraform apply    (type yes to create resources)
#   6. Run: terraform destroy  (type yes to delete everything when done)
#
# PREREQUISITES:
#   - AWS CLI installed and configured (aws configure)
#   - Terraform installed
#   - SSH key pair generated: ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-ec2-key
#
# .gitignore — add these lines to your project's .gitignore:
#   terraform/.terraform/
#   terraform/terraform.tfstate
#   terraform/terraform.tfstate.backup
# =============================================================================


# -----------------------------------------------------------------------------
# TERRAFORM BLOCK
# Declares which providers (cloud SDKs) this config needs.
# Terraform downloads these from registry.terraform.io during "terraform init".
# "~> 5.0" means: any version >=5.0 and <6.0
# -----------------------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# -----------------------------------------------------------------------------
# PROVIDER BLOCK
# Tells Terraform to use AWS and which region to create resources in.
# Credentials come from your "aws configure" setup (~/.aws/credentials).
# No passwords are hardcoded here.
# -----------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region
}


# -----------------------------------------------------------------------------
# DATA SOURCE: LATEST UBUNTU AMI
# Instead of hardcoding an AMI ID (which changes per region and over time),
# this dynamically finds the latest Ubuntu 22.04 LTS image.
# owners = ["099720109477"] is Canonical's (Ubuntu's company) official AWS ID.
# This ensures you always get the official, up-to-date Ubuntu image.
# -----------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# -----------------------------------------------------------------------------
# KEY PAIR
# Uploads your local SSH public key to AWS.
# AWS stores the public key and uses it to allow SSH access to your EC2.
# Your private key (~/.ssh/aws-ec2-key) stays only on your machine.
# Never share or commit your private key.
# -----------------------------------------------------------------------------
resource "aws_key_pair" "deployer" {
  key_name   = "aws-ec2-key"                  # Name shown in AWS Console
  public_key = file(var.public_key_path)       # Reads your .pub file content
}


# -----------------------------------------------------------------------------
# SECURITY GROUP (Firewall)
# Controls what network traffic is allowed in and out of your EC2 instance.
#
# ingress = inbound rules (traffic coming INTO your server)
# egress  = outbound rules (traffic going OUT from your server)
#
# cidr_blocks = ["0.0.0.0/0"] means allow from ANY IP address
# protocol "-1" with port 0 means ALL protocols and ALL ports
#
# PORTS EXPLAINED:
#   22   → SSH (to connect to server via terminal)
#   80   → HTTP (standard web traffic)
#   3000 → Node.js/Express backend API
#   4000 → Admin frontend (Nginx)
#   4001 → User frontend (Nginx)
#
# CUSTOMIZE: Add or remove ingress blocks based on your app's ports.
# -----------------------------------------------------------------------------
resource "aws_security_group" "main_sg" {
  name        = "main-security-group"          # <REPLACE_THIS> e.g. "myapp-sg"
  description = "Security group for app"       # <REPLACE_THIS>

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4001
    to_port     = 4001
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


# -----------------------------------------------------------------------------
# EC2 INSTANCE (Your Linux Server)
#
# ami            → The OS image to use (Ubuntu 22.04 from the data source above)
# instance_type  → The hardware size. t3.micro = 1 vCPU, 1GB RAM (free tier)
# key_name       → Links the key pair so you can SSH in
# vpc_security_group_ids → Attaches the firewall rules above
#
# user_data → A bash script that runs ONCE automatically when the server
#             first boots. Used here to install Docker and Docker Compose.
#             The server will be ready to run containers on first SSH login.
#
# tags → Metadata labels shown in AWS Console. Name tag appears as the
#        instance name in the EC2 dashboard.
#
# FREE TIER NOTE:
#   Older AWS accounts → use "t2.micro"
#   Newer AWS accounts (2024+) → use "t3.micro"
#   If you get "not eligible for Free Tier" error, switch to the other one.
# -----------------------------------------------------------------------------
resource "aws_instance" "main_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"              # or "t2.micro" for older accounts
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.main_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    usermod -aG docker ubuntu
    systemctl enable docker
    systemctl start docker
  EOF

  tags = {
    Name = "app-server"                            # <REPLACE_THIS> shown in AWS Console
  }
}


# -----------------------------------------------------------------------------
# S3 BUCKET (File/Image Storage)
# A globally unique storage bucket for files like blog images.
# Bucket name must be unique across ALL of AWS worldwide — add your
# username or a random number to ensure uniqueness.
#
# force_destroy = false means Terraform won't delete the bucket if it has
# files in it. Change to true if you want "terraform destroy" to wipe it.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "storage" {
  bucket = var.s3_bucket_name

  tags = {
    Name = "app-storage"                           # <REPLACE_THIS>
  }
}


# -----------------------------------------------------------------------------
# S3 PUBLIC ACCESS BLOCK
# AWS blocks all public access by default. Setting all to false here
# allows us to then apply a bucket policy that grants public READ access.
# This is needed so visitors can view images stored in S3.
# If your bucket stores private files only, keep all set to true.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


# -----------------------------------------------------------------------------
# S3 BUCKET POLICY
# A JSON policy that explicitly allows anyone (Principal: "*") to
# perform the s3:GetObject action (download/read files).
# This is what makes uploaded images publicly viewable in a browser.
#
# depends_on ensures the public access block is removed BEFORE this
# policy is applied — otherwise AWS would reject it.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "storage_public_read" {
  bucket = aws_s3_bucket.storage.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.storage.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.storage]
}
