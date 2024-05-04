resource "aws_ecr_repository" "sistema-maika-repository" {
  name                 = "sistema-maika-repository"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "chat-repository" {
  name = "chat-repository"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "sistema-maika-repository-lifecycle" {
  repository = aws_ecr_repository.sistema-maika-repository.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 3 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 3
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

resource "aws_ecr_lifecycle_policy" "chat-repository-lifecycle" {
  repository = aws_ecr_repository.chat-repository.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 3 images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 3
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
