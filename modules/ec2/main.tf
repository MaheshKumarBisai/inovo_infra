variable "ami_id" {
  description = "Custom AMI ID (optional, defaults to latest Amazon Linux 2023)"
  type        = string
  default     = ""
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "subnet_id" {
  type = string
}

variable "security_groups" {
  description = "List of VPC Security Group IDs"
  type        = list(string)
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
}

variable "key_name" {
  type    = string
  default = ""
}

variable "name_prefix" {
  type = string
}

output "instance_id" {
  value = aws_instance.this.id
}

output "private_ip" {
  value = aws_instance.this.private_ip
}

# -------------------------------------------------------
# Default AMI lookup: Latest Amazon Linux 2023 AMI
# -------------------------------------------------------
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "this" {
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_groups
  iam_instance_profile   = var.iam_instance_profile_name
  key_name               = var.key_name != "" ? var.key_name : null

  # No public IP - instances are in private subnets
  associate_public_ip_address = false

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              EOF

  tags = {
    Name = "${var.name_prefix}"
  }
}
