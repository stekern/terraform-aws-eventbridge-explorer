data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  current_account_id = data.aws_caller_identity.current.account_id
  current_region     = data.aws_region.current.name
}

data "archive_file" "this" {
  type                    = "zip"
  source_content          = <<EOF
import json
import logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
def lambda_handler(event, context):
    logger.debug(json.dumps(event, indent=4, sort_keys=True))
EOF
  source_content_filename = "main.py"
  output_path             = "${path.module}/.terraform_artifacts/source.zip"
}

resource "aws_lambda_function" "this" {
  function_name    = "${var.name_prefix}-eventbridge-explorer"
  role             = aws_iam_role.this.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  timeout          = var.lambda_timeout
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
  tags             = var.tags
}

resource "aws_iam_role" "this" {
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "logs_to_lambda" {
  policy = data.aws_iam_policy_document.logs_for_lambda.json
  role   = aws_iam_role.this.id
}

resource "aws_cloudwatch_event_rule" "this" {
  event_pattern = var.event_pattern
  tags          = var.tags
}

resource "aws_cloudwatch_event_target" "this" {
  arn  = aws_lambda_function.this.arn
  rule = aws_cloudwatch_event_rule.this.name
}

resource "aws_lambda_permission" "this" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this.arn
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = 14
  tags              = var.tags
}
