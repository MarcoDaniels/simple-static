terraform {
  backend "remote" {
    organization = "MarcoDaniels"

    workspaces {
      name = "simple-static"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.70.0"
    }

    dhall = {
      source  = "awakesecurity/dhall"
      version = "0.0.1"
    }
  }
}

data "dhall" "config" {
  entrypoint = "./config.dhall"
}

locals {
  config  = jsondecode(data.dhall.config.result)
  aws     = local.config.aws
  project = local.config.project
}

provider "aws" {
  region     = local.aws.region
  access_key = local.aws.accessKey
  secret_key = local.aws.secretKey
}

// S3
// TODO: create user to upload to bucket
resource "aws_s3_bucket" "bucket" {
  bucket_prefix = local.aws.bucketPrefix
  acl           = "private"
}

data "aws_iam_policy_document" "bucket-policy" {
  statement {
    sid       = "OAIRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.bucket-policy.json
}

// CloudFront
resource "aws_cloudfront_origin_access_identity" "oai" {}

resource "aws_cloudfront_distribution" "distribution" {
  enabled         = true
  is_ipv6_enabled = true

  comment     = "Distribution for ${local.project.description}"
  price_class = "PriceClass_100"

  default_cache_behavior {
    target_origin_id = "static-website"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "origin-request"
      lambda_arn = aws_lambda_function.lambda.qualified_arn
    }

    min_ttl     = 60
    default_ttl = 3600
    max_ttl     = 86400
  }

  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = "static-website"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

// lambda@edge
data "aws_iam_policy_document" "lambda-edge" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "edgelambda.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "lambda-logs" {
  statement {
    actions   = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_role" "lambda-edge" {
  name_prefix        = "simple-lambda-edge"
  assume_role_policy = data.aws_iam_policy_document.lambda-edge.json
}

resource "aws_iam_policy" "lambda-logs" {
  name_prefix = "simple-lambda-logs"
  path        = "/"
  policy      = data.aws_iam_policy_document.lambda-logs.json
}

resource "aws_iam_role_policy_attachment" "lambda-logs" {
  role       = aws_iam_role.lambda-edge.name
  policy_arn = aws_iam_policy.lambda-logs.arn
}

variable "replacements" {
  type    = map(any)
  default = {}
}

data "archive_file" "zip" {
  type        = "zip"
  output_path = "${path.module}/dist/index.zip"

  source {
    content  = templatefile("${path.module}/lambda/index.js", var.replacements)
    filename = "index.js"
  }

  source {
    content  = templatefile("${path.module}/lambda/Main.js", var.replacements)
    filename = "Main.js"
  }
}

resource "aws_lambda_function" "lambda" {
  publish = true

  function_name    = "elm-response"
  role             = aws_iam_role.lambda-edge.arn
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  handler          = "index.handler"
  runtime          = "nodejs14.x"

  depends_on = [
    aws_iam_role_policy_attachment.lambda-logs,
  ]
}

output "cloudfront-domain" {
  value = "https://${aws_cloudfront_distribution.distribution.domain_name}"
}
