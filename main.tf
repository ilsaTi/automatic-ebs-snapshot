terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = lookup(var.props, "region")
}

data "local_file" "lambda_policy" {
  filename = "policy/policy.json"
}

data "local_file" "lambda_assumeRole_policy" {
  filename = "policy/assumeRole.json"
}

# lambda function
resource "aws_lambda_function" "function_ebs" {
  filename      = "code/index.zip"
  function_name = "automatic_ebs_snapshot"
  role          = aws_iam_role.lambda_assumeRole_policy.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  environment {
    variables = {
        TAG_KEY = lookup(var.parameters,"tag_key"),
        TAG_VALUE = lookup(var.parameters,"tag_value")
    }
  }
  timeout = 600
  tags = var.tags
}

# iam role
resource "aws_iam_role" "lambda_assumeRole_policy" {
  name = "ebsSnapshotPolicy"
  assume_role_policy = data.local_file.lambda_assumeRole_policy.content
}

# iam policy
resource "aws_iam_role_policy" "pol" {
  name = "policy"
  role = aws_iam_role.lambda_assumeRole_policy.id
  policy = replace(data.local_file.lambda_policy.content, "ACCOUNT_ID", lookup(var.props,"account_id")) # substitue the account_id in policy.json for cloudwatch logs
}

# ----- EventBridge rule ----- 
resource "aws_cloudwatch_event_rule" "event_rule" {
  name        = "automatic_ebs_snapshot_rule"
  description = "Automatic rule for EBS snapshot creation"
  schedule_expression = lookup(var.schedule, "start")
  is_enabled = true
}

resource "aws_cloudwatch_event_target" "target" {
  target_id = aws_lambda_function.function_ebs.id
  rule      = aws_cloudwatch_event_rule.event_rule.name
  arn       = aws_lambda_function.function_ebs.arn
}