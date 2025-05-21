resource "aws_lambda_function" "from_ecr" {
  function_name = "currency-data-lambda"
  package_type  = "Image"

  architectures = ["arm64"]
  image_uri     = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/${var.image_repo}:latest"

  role = aws_iam_role.lambda_exec.arn

  timeout = 360

  vpc_config {
    subnet_ids         = [data.aws_subnet.default.id, data.aws_subnet.defaultb.id, data.aws_subnet.defaultc.id]
    security_group_ids = [aws_security_group.db_sg.id]
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-ecr-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "sm_policy" {
  name = "s3_sm_access_permissions"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:*", 
          "s3:*",
            "ec2:*",
            "kms:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}