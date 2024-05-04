resource "aws_iam_user" "sistema-maika" {
  name = "sistema-maika"
}

resource "aws_iam_policy" "policy-s3-files" {
  name        = "policy-s3-files"
  path        = "/"
  description = "Policy for app User to access the files bucket"
  policy      = file("policy-s3-files.json")
}

resource "aws_iam_policy" "policy-ecr-full-access" {
  name        = "policy-ecr-full-access"
  path        = "/"
  description = "Policy for Amazon ECR Full Access"
  policy      = file("ecr-full-access.json")
}

resource "aws_iam_policy" "policy-cloudfront-invalidation" {
  name = "policy-cloudfront-invalidation"
  path = "/"
  description = "Policy for Cloudfront Invalidation on all Distributions"
  policy = file("cloudfront-invalidation.json")
}

resource "aws_iam_policy" "github-actions-permissions" {
  name = "github-actions-permissions"
  path = "/"
  description = "Policy for Github Actions permissions needed to perform the CI/CD pipeline"
  policy = file("github-actions-policy.json")
}

resource "aws_iam_policy" "dynamodb-table-permissions" {
  name = "dynamodb-table-permissions"
  path = "/"
  description = "Policy for DynamoDB Table CRUD permissions"
  policy = file("dynamodb-access.json")
}

data "aws_iam_policy_document" "api-lambda-permissions" {
  statement {
    effect = "Allow"

    actions = [
      "execute-api:Invoke"
    ]

    resources = ["${aws_api_gateway_rest_api.lambda_api.execution_arn}/*/*"]
  }
}

resource "aws_iam_policy" "api-lambda-permissions" {
  name        = "api-lambda-permissions"
  path        = "/"
  description = "IAM policy for invoking Lambda API"
  policy      = data.aws_iam_policy_document.api-lambda-permissions.json
}

resource "aws_iam_user_policy_attachment" "attachment" {
  user       = aws_iam_user.sistema-maika.name
  policy_arn = aws_iam_policy.policy-s3-files.arn
}

resource "aws_iam_user_policy_attachment" "attachment2" {
  user = aws_iam_user.sistema-maika.name
  policy_arn = aws_iam_policy.policy-ecr-full-access.arn
}

resource "aws_iam_user_policy_attachment" "attachment3" {
  user = aws_iam_user.sistema-maika.name
  policy_arn = aws_iam_policy.policy-cloudfront-invalidation.arn
}

resource "aws_iam_user_policy_attachment" "attachment4" {
  user = aws_iam_user.sistema-maika.name
  policy_arn = aws_iam_policy.github-actions-permissions.arn
}

resource "aws_iam_user_policy_attachment" "attachment5" {
  user = aws_iam_user.sistema-maika.name
  policy_arn = aws_iam_policy.dynamodb-table-permissions.arn
}

resource "aws_iam_user_policy_attachment" "attachment6" {
  user = aws_iam_user.sistema-maika.name
  policy_arn = aws_iam_policy.api-lambda-permissions.arn
}

resource "aws_iam_user_policy_attachment" "attachment7" {
  user = aws_iam_user.sistema-maika.name
  policy_arn = data.aws_iam_policy.SSMFullAccess.arn
}

resource "aws_iam_role" "sistema-maika-role" {
  name = "sistema-maika-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com",
      },
    }],
  })

  managed_policy_arns = [
    aws_iam_policy.policy-s3-files.arn,
    aws_iam_policy.policy-ecr-full-access.arn,
    aws_iam_policy.policy-cloudfront-invalidation.arn
  ]
}

resource "aws_iam_instance_profile" "sistema-maika-instance-profile" {
  name = "sistema-maika-instance-profile"

  role = aws_iam_role.sistema-maika-role.name
}

resource "aws_iam_access_key" "sistema-maika-access-key" {
  user = aws_iam_user.sistema-maika.name
}
