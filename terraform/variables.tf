variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "public_key" {
  description = "Public key for SSH access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_management_cidr" {
  description = "CIDR blocks allowed for management interfaces"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "git_repository" {
  description = "Git repository URL for the payment system"
  type        = string
  default     = "https://github.com/your-username/payment-system.git"
}

variable "enable_load_balancer" {
  description = "Enable Application Load Balancer"
  type        = bool
  default     = false
} 