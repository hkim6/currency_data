resource "aws_s3_bucket" "de_exercise" {
  bucket = "the-bucket-de-exercise"

  tags = {
    Name        = "The s3 bucket"
  }
}