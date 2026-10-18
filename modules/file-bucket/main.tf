locals {
  # From staging up, an environment is held to production's rules (see the README).
  upper_stage = contains(["staging", "perf", "prod"], var.stage)
  full_name   = "${var.name}-${var.stage}"
  tags = merge(var.tags, {
    "juniper:app"     = var.name
    "juniper:stage"   = var.stage
    "juniper:module"  = "file-bucket"
    "juniper:library" = "platform-library"
  })
}

resource "aws_s3_bucket" "files" {
  bucket = "juniper-files-${local.full_name}"
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "files" {
  bucket                  = aws_s3_bucket.files.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "files" {
  bucket = aws_s3_bucket.files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "files" {
  bucket = aws_s3_bucket.files.id

  versioning_configuration {
    status = local.upper_stage ? "Enabled" : "Suspended"
  }
}

# What an app needs to use the bucket, as policies the app's module attaches to the
# app's role (its policy_arns input).
data "aws_iam_policy_document" "read_write" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.files.arn]
  }
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.files.arn}/*"]
  }
}

data "aws_iam_policy_document" "read_only" {
  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.files.arn]
  }
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.files.arn}/*"]
  }
}

resource "aws_iam_policy" "read_write" {
  name   = "${local.full_name}-files-read-write"
  policy = data.aws_iam_policy_document.read_write.json
  tags   = local.tags
}

resource "aws_iam_policy" "read_only" {
  name   = "${local.full_name}-files-read-only"
  policy = data.aws_iam_policy_document.read_only.json
  tags   = local.tags
}
