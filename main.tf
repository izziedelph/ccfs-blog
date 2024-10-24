provider "aws" {
    region = "us-east-1"
}


data "aws_region" "current" {}


# S3 Bucket
resource "aws_s3_bucket" "blog_bucket" {
  bucket = "my-serverless-blog"
}

resource "aws_s3_bucket_public_access_block" "blog_bucket_public" {
  bucket = aws_s3_bucket.blog_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "blog_bucket_website" {
  bucket = aws_s3_bucket.blog_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Update S3 bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "blog_bucket_policy" {
  bucket = aws_s3_bucket.blog_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontAccess"
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.oai.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.blog_bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.blog_bucket_public]
}



# DynamoDB Table
resource "aws_dynamodb_table" "blog_posts" {
  name         = "BlogPosts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PostID"

  attribute {
    name = "PostID"
    type = "S"
  }
}

# Lambda Role
resource "aws_iam_role" "lambda_role" {
  name = "blog_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Lambda DynamoDB Policy
resource "aws_iam_role_policy" "lambda_dynamo_policy" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:Scan"
      ]
      Resource = aws_dynamodb_table.blog_posts.arn
    }]
  })
}

# Lambda Basic Execution Role
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Function
resource "aws_lambda_function" "blog_function" {
  filename      = "lambda.zip"
  function_name = "blog_function"
  role         = aws_iam_role.lambda_role.arn
  handler      = "lambda_function.lambda_handler"
  runtime      = "nodejs18.x"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.blog_posts.name
    }
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "blog_api" {
  name = "BlogAPI"
}

resource "aws_api_gateway_resource" "posts" {
  rest_api_id = aws_api_gateway_rest_api.blog_api.id
  parent_id   = aws_api_gateway_rest_api.blog_api.root_resource_id
  path_part   = "posts"
}

resource "aws_api_gateway_method" "get_posts" {
  rest_api_id   = aws_api_gateway_rest_api.blog_api.id
  resource_id   = aws_api_gateway_resource.posts.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.blog_api.id
  resource_id = aws_api_gateway_resource.posts.id
  http_method = aws_api_gateway_method.get_posts.http_method
  
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.blog_function.invoke_arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.blog_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.blog_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "prod" {
  depends_on = [
    aws_api_gateway_integration.lambda
  ]

  rest_api_id = aws_api_gateway_rest_api.blog_api.id
  stage_name  = "prod"
}

# Cognito User Pool
resource "aws_cognito_user_pool" "blog_user_pool" {
  name = "ccfs-blog-users"

  username_attributes = ["email"]
  
  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Password policy
  password_policy {
    minimum_length    = 8
    require_numbers   = true
    require_symbols   = true
    require_lowercase = true
    require_uppercase = true
  }

  # Email verification
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject = "CCFS Blog - Verify your email"
    email_message = "Your verification code is {####}"
  }

  # Auto verify email
  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type = "String"
    name               = "name"
    required           = true
    mutable           = true

    string_attribute_constraints {
      min_length = 2
      max_length = 50
    }
  }
}

# Cognito App Client
resource "aws_cognito_user_pool_client" "blog_client" {
  name         = "ccfs-blog-client"
  user_pool_id = aws_cognito_user_pool.blog_user_pool.id

  generate_secret = false
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]
}


# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for blog bucket"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "blog_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  
  origin {
    domain_name = aws_s3_bucket.blog_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.blog_bucket.bucket}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.blog_bucket.bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # This is important for SPA routing
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_100"
}





output "website_url" {
  value = "http://${aws_s3_bucket.blog_bucket.bucket}.s3-website-${data.aws_region.current.name}.amazonaws.com"
}


# Outputs
output "api_url" {
  value = "${aws_api_gateway_deployment.prod.invoke_url}/posts"
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.blog_user_pool.id
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.blog_client.id
}


output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.blog_distribution.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.blog_distribution.domain_name
}

output "cloudfront_url" {
  value = "https://${aws_cloudfront_distribution.blog_distribution.domain_name}"
}