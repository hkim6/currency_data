module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"

  create_bus = false

  rules = {
    crons = {
      description         = "Trigger for a Lambda"
      schedule_expression = "rate(1 day)"
    }
  }

  targets = {
    crons = [
      {
        name  = "1-day-lambda"
        arn   = aws_lambda_function.from_ecr.arn
        input = jsonencode({"job": "cron-by-rate"})
      }
    ]
  }
}