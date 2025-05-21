resource "aws_s3_bucket" "cd_exercise" {
  bucket = "the-bucket-currency-data-exercise"

  tags = {
    Name        = "The s3 bucket"
  }
}