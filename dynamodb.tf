resource "aws_dynamodb_table" "sistema-maika-table" {
  name           = "sistema-maika"
  billing_mode   = "PROVISIONED"
  read_capacity  = 15
  write_capacity = 10
  hash_key       = "pk"
  range_key      = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  tags = {
    Name        = "sistema-maika"
    Environment = "production"
  }
}
