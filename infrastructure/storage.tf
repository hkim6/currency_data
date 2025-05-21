resource "aws_s3_bucket" "cd" {
  bucket = "the-bucket-currency-data"

  tags = {
    Name        = "The s3 bucket"
  }
}