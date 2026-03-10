provider "aws" {
  region = "ap-southeast-2"
}



resource "aws_s3_bucket" "example" {
  bucket = "my-unique-buckets-name-12345-test-1010"
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_object" "example" {
  bucket = aws_s3_bucket.example.id
  key    = "finance-2025.docx"
  content = "This is an example file stored in S3."
  tags = {
    Name        = "Example object"
    Environment = "Dev"
  }
}

# Create the IAM group (instead of reading a non-existent one)
resource "aws_iam_group" "finance_analysts" {
  name = "finance-analysts"
}

# Read-only access to the specific S3 bucket for the group
resource "aws_iam_policy" "finance_bucket_read" {
  name        = "finance-analysts-s3-read"
  description = "Read-only access to the example S3 bucket objects and list bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.example.arn
      },
      {
        Sid    = "GetObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.example.arn}/*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "finance_read_attach" {
  group      = aws_iam_group.finance_analysts.name
  policy_arn = aws_iam_policy.finance_bucket_read.arn
}
