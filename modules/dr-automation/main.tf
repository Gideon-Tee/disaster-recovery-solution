# Lambda, EventBridge, SSM Automation

# SSM Automation Document to create AMI
resource "aws_ssm_document" "create_ami" {
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
  schedule_expression = "cron(0 2 * * ? *)" # Run daily at 2 AM UTC
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