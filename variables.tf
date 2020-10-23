variable "name_prefix" {
  description = "A prefix used for naming resources."
  type        = string
}

variable "event_pattern" {
  description = <<DOC
The CloudWatch Event pattern that will trigger the Lambda.

E.g., event_pattern = <<EOF
{
  "source": [
    "aws.ssm"
  ]
}
EOF
DOC
  type        = string
}

variable "lambda_timeout" {
  description = "The maximum number of seconds the Lambda is allowed to run"
  default     = 30
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default     = {}
}
