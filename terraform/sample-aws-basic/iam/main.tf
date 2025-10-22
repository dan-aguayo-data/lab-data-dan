provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_iam_user" "admin-user" {
    name = "lucy"
    tags = {
        Description = "Technical Team Leader"
    }
}

resource "aws_iam_policy" "admin-users-policy" {
    name       = "AdminUsers"
    policy = file("admin-policy.json")
}

resource "aws_iam_user_policy_attachment" "admin-user-attach" {
    user       = aws_iam_user.admin-user.name
    policy_arn = aws_iam_policy.admin-users-policy.arn
}