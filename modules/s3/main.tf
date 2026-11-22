variable "bucket_name" {
  type = string
}

output "bucket_name" {
  value = aws_s3_bucket.avatars.id
}

output "bucket_arn" {
  value = aws_s3_bucket.avatars.arn
}

resource "aws_s3_bucket" "avatars" {
  bucket        = var.bucket_name != "" && var.bucket_name != "prod-inovo-bucket" ? var.bucket_name : null
  bucket_prefix = var.bucket_name == "" || var.bucket_name == "prod-inovo-bucket" ? "inovo-avatars-" : null
  tags          = { Name = "inovo-avatars" }
}

resource "aws_s3_bucket_public_access_block" "avatars" {
  bucket = aws_s3_bucket.avatars.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
