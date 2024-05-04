resource "aws_s3_bucket" "file_storage" {
  bucket = "maika-reportes"
  tags = {
    name = "maika-reportes"
    environment = "production"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "life_cycle" {
  bucket = aws_s3_bucket.file_storage.id
  rule {
    status = "Enabled"
    id     = "expire_all_files"
    expiration {
      days = 15
    }
  }
}

resource "aws_s3_bucket" "maikadb-backups" {
  bucket = "maikadb-backups"
}

resource "aws_s3_bucket_lifecycle_configuration" "life_cycle-2" {
  bucket = aws_s3_bucket.maikadb-backups.id
  rule {
    status = "Enabled"
    id     = "expire_all_files"
    expiration {
      days = 15
    }
  }
}
