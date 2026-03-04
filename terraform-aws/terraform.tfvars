# =============================================================================
# TERRAFORM VARIABLE VALUES
# This file sets the actual values for variables declared in variables.tf.
# This is the ONLY file you need to edit when reusing this template.
#
# IMPORTANT: If your .tfvars contains sensitive values (access keys, passwords),
# add it to .gitignore. This file is safe to commit as-is since it only
# contains region, key path, bucket name, and instance type.
#
# NEVER put AWS secret keys or passwords in this file.
# Credentials come from "aws configure" (stored in ~/.aws/credentials).
# =============================================================================


# AWS region where all resources will be created.
# Find your nearest region: https://aws.amazon.com/about-aws/global-infrastructure/regions_az/
# Examples:
#   "ap-south-1"    → Mumbai, India
#   "us-east-1"     → N. Virginia, USA
#   "eu-west-1"     → Ireland, Europe
#   "ap-southeast-1"→ Singapore
aws_region = "ap-south-1"   # <REPLACE_THIS>


# Path to your SSH public key on your local machine.
# If you don't have one yet, generate it first:
#   ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws-ec2-key
# This will create two files:
#   ~/.ssh/aws-ec2-key      → private key (NEVER share this)
#   ~/.ssh/aws-ec2-key.pub  → public key (uploaded to AWS)
public_key_path = "~/.ssh/aws-ec2-key.pub"


# Name for the S3 bucket. Must be GLOBALLY UNIQUE across all of AWS.
# Good naming strategy: <project>-<purpose>-<yourusername>
# Bad examples: "my-bucket", "storage" (already taken by someone)
# Good examples: "myblog-images-johndoe", "myapp-assets-jane2024"
s3_bucket_name = "your-unique-bucket-name-here"   # <REPLACE_THIS>


# EC2 instance size.
# For Free Tier:
#   - Newer AWS accounts (2024+): use "t3.micro"
#   - Older AWS accounts: use "t2.micro"
# If you get "not eligible for Free Tier" error, switch to the other one.
instance_type = "t3.micro"
