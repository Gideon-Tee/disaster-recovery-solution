# Lambda, EventBridge, SSM Automation

# SSM Automation Document to create AMI
resource "aws_ssm_document" "create_ami" {
  name = "CreateAMIFromInstance"
  document_type = "Automation"
  document_format = "YAML"

  content = <<DOC
schemaVersion: '0.3'
description: Create and copy AMI to DR region
assumeRole: "{{ AutomationAssumeRole }}"
parameters:
  InstanceId:
    type: String
    description: The ID of the EC2 instance to create an AMI from
  AutomationAssumeRole:
    type: String
    description: The ARN of the role to assume for automation
  DestinationRegion:
    type: String
    description: The destination region for AMI copy
    default: "${var.dr_region}"
mainSteps:
  - name: CreateImage
    action: aws:executeAwsApi
    inputs:
      Service: ec2
      Api: CreateImage
      InstanceId: "{{ InstanceId }}"
      Name: "App-AMI-{{ global:DATE_TIME }}"
      NoReboot: true
    outputs:
      - Name: ImageId
        Selector: $.ImageId
        Type: String
  - name: TagImage
    action: aws:executeAwsApi
    inputs:
      Service: ec2
      Api: CreateTags
      Resources:
        - "{{ CreateImage.ImageId }}"
      Tags:
        - Key: Name
          Value: "App-AMI-{{ global:DATE_TIME }}"
  - name: CopyImage
    action: aws:executeAwsApi
    inputs:
      Service: ec2
      Api: CopyImage
      SourceImageId: "{{ CreateImage.ImageId }}"
      SourceRegion: "${var.primary_region}"
      Name: "App-AMI-{{ global:DATE_TIME }}-DR"
      Region: "{{ DestinationRegion }}"
    outputs:
      - Name: CopiedImageId
        Selector: $.ImageId
        Type: String
  - name: TagCopiedImage
    action: aws:executeAwsApi
    inputs:
      Service: ec2
      Api: CreateTags
      Resources:
        - "{{ CopyImage.CopiedImageId }}"
      Tags:
        - Key: Name
          Value: "App-AMI-{{ global:DATE_TIME }}-DR"
DOC
}

# IAM Role for SSM Automation
resource "aws_iam_role" "ssm_automation_role" {
  name = "SSMAutomationRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ssm.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ssm_automation_policy" {
  name   = "SSMAutomationPolicy"
  role   = aws_iam_role.ssm_automation_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ec2:CreateImage",
          "ec2:CreateTags",
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:CopyImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# EventBridge Rule to trigger AMI creation periodically (e.g., daily)
resource "aws_cloudwatch_event_rule" "ami_creation_schedule" {
  name                = "AMICreationSchedule"
  description         = "Triggers SSM Automation to create AMI daily"
  schedule_expression = "cron(0 2 * * ? *)" # Run daily at 2 AM
}

resource "aws_cloudwatch_event_target" "ami_creation_target" {
  rule      = aws_cloudwatch_event_rule.ami_creation_schedule.name
  target_id = "RunSSMAutomation"
  arn       = "arn:aws:ssm:${var.primary_region}::automation-definition/${aws_ssm_document.create_ami.name}:$DEFAULT"
  role_arn  = aws_iam_role.ssm_automation_role.arn

  input = jsonencode({
    InstanceId           = var.primary_instance_id # Reference the primary instance ID
    AutomationAssumeRole = aws_iam_role.ssm_automation_role.arn
    DestinationRegion = var.dr_region
  })
}

# Store latest AMI ID in Parameter Store
# resource "aws_ssm_parameter" "latest_ami" {
#   provider = aws.dr
#   name     = "/app/latest-ami-id"
#   type     = "String"
#   value    = "placeholder" # Will be updated by Lambda
#   overwrite = true
# }

# CloudWatch Alarm for Primary ALB (HealthyHostCount)
resource "aws_cloudwatch_metric_alarm" "primary_alb_healthy_hosts" {
  alarm_name          = "PrimaryALBHealthyHosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60 # 1 minute
  statistic           = "Average"
  threshold           = 1 # Alarm if fewer than 1 healthy host
  alarm_description   = "Triggers when the primary ALB has fewer than 1 healthy host"
  treat_missing_data  = "breaching" # Treat missing data as unhealthy

  dimensions = {
    LoadBalancer = var.primary_alb_arn_suffix # ARN suffix of the primary ALB
    TargetGroup  = var.primary_target_group_arn_suffix
  }

  # Placeholder for SNS topic or Lambda trigger
  alarm_actions = [aws_sns_topic.failover_notifications.arn]
  ok_actions    = []
}

# CloudWatch Alarm for Primary RDS (CPUUtilization)
resource "aws_cloudwatch_metric_alarm" "primary_rds_cpu" {
  alarm_name          = "PrimaryRDSCPUUtilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60 # 1 minute
  statistic           = "Average"
  threshold           = 80 # Alarm if CPU utilization exceeds 80%
  alarm_description   = "Triggers when the primary RDS CPU utilization exceeds 80%"
  treat_missing_data  = "breaching" # Treat missing data as unhealthy

  dimensions = {
    DBInstanceIdentifier = var.primary_rds_identifier
  }

  # Placeholder for SNS topic or Lambda trigger (to be added later)
  alarm_actions = [aws_sns_topic.failover_notifications.arn]
  ok_actions    = []
}


# SNS Topic for CloudWatch Alarms
resource "aws_sns_topic" "failover_notifications" {
  name = "FailoverNotifications"
}

# SNS Topic Policy to allow CloudWatch to publish
resource "aws_sns_topic_policy" "failover_notifications_policy" {
  arn = aws_sns_topic.failover_notifications.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudwatch.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.failover_notifications.arn
      }
    ]
  })
}

# Lambda Function for Failover
resource "aws_lambda_function" "failover_handler" {
  filename      = "${path.module}/failover_lambda.zip"
  function_name = "FailoverHandler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "failover_lambda.handler"
  runtime       = "python3.9"
  timeout       = 60

  environment {
    variables = {
      DR_REGION            = var.dr_region
      DR_RDS_IDENTIFIER    = var.dr_rds_identifier
      DR_ASG_NAME          = var.dr_asg_name
      DR_S3_BUCKET_NAME    = var.dr_s3_bucket_name
      SSM_S3_PARAM_NAME    = "/dr/s3-bucket-name"
      SSM_RDS_PARAM_NAME   = "/dr/rds-endpoint"
    }
  }
}

# Package Lambda Code
data "archive_file" "failover_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/failover_lambda.py"
  output_path = "${path.module}/failover_lambda.zip"
}

# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name = "FailoverLambdaRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "FailoverLambdaPolicy"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "rds:PromoteReadReplica",
          "rds:DescribeDBInstances" # Added missing permission
        ]
        Resource = [
          "arn:aws:rds:${var.dr_region}:${var.account_id}:db:${var.dr_rds_identifier}",
          "arn:aws:rds:${var.primary_region}:${var.account_id}:db:${var.primary_rds_identifier}"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "autoscaling:UpdateAutoScalingGroup"
        Resource = "arn:aws:autoscaling:${var.dr_region}:${var.account_id}:autoScalingGroup:*:autoScalingGroupName/${var.dr_asg_name}"
      },
      {
        Effect   = "Allow"
        Action   = [
          "ssm:PutParameter",
          "ssm:GetParameter"
        ]
        Resource = [
          "arn:aws:ssm:${var.dr_region}:${var.account_id}:parameter/app/s3-bucket-name",
          "arn:aws:ssm:${var.dr_region}:${var.account_id}:parameter/app/rds-endpoint"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda Permission for SNS
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.failover_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.failover_notifications.arn
}

# SNS Subscription for Lambda
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.failover_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.failover_handler.arn
}
