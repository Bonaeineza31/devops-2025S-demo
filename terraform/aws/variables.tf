variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "my_ip_cidr" {
  type        = string
  description = "Your public IP in CIDR format"
}

variable "public_key_path" {
  type        = string
  description = "Path to the public SSH key"
  default     = "~/.ssh/alu-devops.pub"
}

