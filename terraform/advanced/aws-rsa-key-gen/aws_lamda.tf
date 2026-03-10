# =============================================================================
# Lambda - RSA Key Generator
# =============================================================================

# -----------------------------------------------------------------------------
# Lambda Layer (built by CI/CD pipeline)
# -----------------------------------------------------------------------------

resource "aws_lambda_layer_version" "cryptography" {
  filename            = "${path.module}/dist/layer.zip"
  layer_name          = "${local.name_prefix}-deps"
  compatible_runtimes = ["python3.11", "python3.12"]
  description         = "cryptography library for RSA key generation"
  
  source_code_hash = filebase64sha256("${path.module}/dist/layer.zip")
}

# -----------------------------------------------------------------------------
# Lambda Function
# -----------------------------------------------------------------------------

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/dist/lambda.zip"
  excludes    = ["requirements.txt"]
}

resource "aws_lambda_function" "key_generator" {
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  function_name    = local.name_prefix
  role             = aws_iam_role.lambda.arn
  handler          = "handler.handler"
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 256

  layers = [aws_lambda_layer_version.cryptography.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.key_generator.function_name}"
  retention_in_days = 14
  tags              = local.common_tags
}

# -----------------------------------------------------------------------------
# Lambda IAM Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "lambda" {
  name = "${local.name_prefix}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:PutSecretValue",
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:data/dwh/snowflake/*"
      }
    ]
  })
}
