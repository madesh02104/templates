# =============================================================================
# VARIABLES
# Variables make your Terraform config reusable. Instead of hardcoding values
# like region or bucket name directly in main.tf, you declare them here and
# set their actual values in terraform.tfvars.
#
# This separation means:
#   - main.tf  → describes WHAT to build (logic, structure)
#   - variables.tf → describes WHAT inputs are accepted
#   - terraform.tfvars → describes the ACTUAL values for THIS project
#
# To reuse this template in a new project, only change terraform.tfvars.
# =============================================================================


# -----------------------------------------------------------------------------
# HOW A VARIABLE BLOCK WORKS:
#
# variable "name_of_variable" {
#   description = "Human-readable explanation shown in CLI output"
#   type        = string | number | bool | list | map  (optional but good practice)
#   default     = "fallback value if not set in .tfvars"  (optional)
# }
#
# If no default is set and the value is missing from .tfvars,
# Terraform will prompt you to enter it manually when you run terraform apply.
# -----------------------------------------------------------------------------


# Which AWS region to deploy all resources in.
# Examples: "us-east-1" (N.Virginia), "ap-south-1" (Mumbai), "eu-west-1" (Ireland)
# Full list: https://docs.aws.amazon.com/general/latest/gr/rande.html
variable "aws_region" {
  description = "The AWS region to deploy all resources in."
  type        = string
  default     = "ap-south-1"
}


# Path to your SSH public key on your LOCAL machine.
# Generated with: ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-ec2-key
# The .pub file is uploaded to AWS as a Key Pair.
# The private key (no extension) stays on your machine and is used to SSH in.
variable "public_key_path" {
  description = "Path to the local SSH public key file (.pub) to upload to AWS."
  type        = string
  default     = "~/.ssh/aws-ec2-key.pub"
}


# S3 bucket names must be globally unique across ALL AWS accounts worldwide.
# Strategy: prefix with your project name or username to avoid conflicts.
# Example: "myapp-storage-yourname-2024"
# No default — this MUST be set in terraform.tfvars.
variable "s3_bucket_name" {
  description = "Globally unique name for the S3 storage bucket."
  type        = string
}


# EC2 instance size. This determines CPU, RAM, and cost.
# t3.micro  → 2 vCPU, 1GB RAM — Free Tier on newer AWS accounts (2024+)
# t2.micro  → 1 vCPU, 1GB RAM — Free Tier on older AWS accounts
# t3.small  → 2 vCPU, 2GB RAM — Paid (~$15/month)
# t3.medium → 2 vCPU, 4GB RAM — Paid (~$30/month)
variable "instance_type" {
  description = "EC2 instance type. Use t3.micro or t2.micro for Free Tier."
  type        = string
  default     = "t3.micro"
}
