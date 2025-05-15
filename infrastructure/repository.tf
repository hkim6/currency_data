resource "aws_ecr_repository" "my-repo" {
  name                 = "hk-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}