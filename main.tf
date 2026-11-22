terraform {
  required_version = ">= 1.5"
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

# -------------------------------------------------------
# Modules: Networking & Base Services
# -------------------------------------------------------
module "vpc" {
  source               = "./modules/vpc"
  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  create_nat_gateway   = true
}

module "security_groups" {
  source = "./modules/security-groups"
  vpc_id = module.vpc.vpc_id
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = var.s3_bucket_name
}

module "ecr" {
  source = "./modules/ecr"
}

module "rds" {
  source                = "./modules/rds"
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  db_instance_class     = var.db_instance_class
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
  rds_security_group_id = module.security_groups.rds_sg_id
}

# -------------------------------------------------------
# IAM role for EC2 (S3 + SSM access)
# -------------------------------------------------------
resource "aws_iam_role" "ec2_s3" {
  name = "inovo-ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_s3" {
  role       = aws_iam_role.ec2_s3.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_s3.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_ecr" {
  role       = aws_iam_role.ec2_s3.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_s3" {
  name = "inovo-ec2-s3-profile"
  role = aws_iam_role.ec2_s3.name
}

# -------------------------------------------------------
# EC2 instances (PRIVATE subnets - no public IP)
# -------------------------------------------------------
module "ec2_backend" {
  source                    = "./modules/ec2"
  name_prefix               = "inovo-backend"
  ami_id                    = var.ami_id
  instance_type             = var.instance_type
  subnet_id                 = module.vpc.private_subnet_ids[0]
  security_groups           = [module.security_groups.backend_sg_id]
  iam_instance_profile_name = aws_iam_instance_profile.ec2_s3.name
  key_name                  = var.key_name
}

module "ec2_gateway" {
  source                    = "./modules/ec2"
  name_prefix               = "inovo-gateway"
  ami_id                    = var.ami_id
  instance_type             = var.instance_type
  subnet_id                 = module.vpc.private_subnet_ids[1]
  security_groups           = [module.security_groups.gateway_sg_id]
  iam_instance_profile_name = aws_iam_instance_profile.ec2_s3.name
  key_name                  = var.key_name
}

# -------------------------------------------------------
# Application Load Balancer
# -------------------------------------------------------
module "alb" {
  source                = "./modules/alb"
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_sg_id
  acm_certificate_arn   = var.acm_certificate_arn
  gateway_instance_id   = module.ec2_gateway.instance_id
  backend_instance_id   = module.ec2_backend.instance_id
}
