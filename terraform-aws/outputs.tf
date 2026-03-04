# =============================================================================
# OUTPUTS
# Output values are printed to your terminal after "terraform apply" finishes.
# They're useful for displaying important info you need after provisioning
# (like an IP address to SSH into, or a bucket name to configure in your app).
#
# They can also be referenced by other Terraform modules if you split your
# infrastructure into multiple configs later.
#
# To view outputs at any time without re-applying:
#   terraform output
#   terraform output ec2_public_ip     (single value)
# =============================================================================


# -----------------------------------------------------------------------------
# HOW AN OUTPUT BLOCK WORKS:
#
# output "name_shown_in_terminal" {
#   description = "Explains what this value is"
#   value       = resource_type.resource_name.attribute
# }
#
# The attribute comes from the resource definition in main.tf.
# You can browse all available attributes in the AWS provider docs.
# -----------------------------------------------------------------------------


# The public IPv4 address of the EC2 instance.
# Use this to: SSH in, configure your domain's DNS A record, or set
# ALLOWED_HOSTS/CORS settings in your backend.
output "ec2_public_ip" {
  description = "The public IPv4 address of the EC2 instance."
  value       = aws_instance.main_server.public_ip
}


# The name of the S3 bucket that was created.
# Use this in your app's environment variables for file uploads.
# Example env var in backend: AWS_S3_BUCKET=<this value>
output "s3_bucket_name" {
  description = "The name of the S3 bucket created."
  value       = aws_s3_bucket.storage.bucket
}


# The base URL for accessing files stored in the S3 bucket publicly.
# Format: https://<bucket-name>.s3.<region>.amazonaws.com/<filename>
# Use this in your frontend to construct image/file URLs.
output "s3_bucket_url" {
  description = "Base URL for publicly accessible files in the S3 bucket."
  value       = "https://${aws_s3_bucket.storage.bucket}.s3.${var.aws_region}.amazonaws.com"
}


# A ready-to-copy SSH command to connect to the EC2 instance.
# -i flag specifies which private key to use for authentication.
# "ubuntu" is the default username for Ubuntu AMIs on AWS.
output "ssh_command" {
  description = "Copy-paste this command to SSH into your EC2 instance."
  value       = "ssh -i ~/.ssh/aws-ec2-key ubuntu@${aws_instance.main_server.public_ip}"
}
