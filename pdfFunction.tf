data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]

    resources = [aws_s3_bucket.file_storage.arn, "${aws_s3_bucket.file_storage.arn}/*",]
  }
}

resource "aws_iam_policy" "lambda_permissions" {
  name        = "lambda_permissions"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_permissions.json
}

resource "aws_iam_role_policy_attachment" "lambda_permissions" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_permissions.arn
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/pdfGenerator"
  retention_in_days = 7
}

resource "aws_lambda_function" "pdfGenerator" {
  function_name = "pdfGenerator"
  handler = "index.handler"
  runtime = "nodejs18.x"
  role = aws_iam_role.iam_for_lambda.arn
  s3_bucket = aws_s3_bucket.maika-assets.id
  s3_key = "lambda/pdfFunction.zip"

  timeout = 15

  memory_size = 1024

  layers = ["arn:aws:lambda:sa-east-1:764866452798:layer:ghostscript:15"]

  depends_on = [
    aws_iam_role_policy_attachment.lambda_permissions,
    aws_cloudwatch_log_group.lambda_logs,
  ]
}

resource "aws_s3_object" "pdfFunctionZip" {
  bucket = aws_s3_bucket.maika-assets.id
  key = "lambda/pdfFunction.zip"
  source = "./pdfFunction/pdfFunction.zip"
}

