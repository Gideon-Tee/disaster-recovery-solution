#!/bin/bash

# edit the ASG instances number to simulate failover
# it triggers the HealthyHostsCounts alarm

# PRIMARY ASG
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name primary-app-asg \
  --desired-capacity 1 --min-size 0

# DR ASG
#aws autoscaling update-auto-scaling-group \
#  --auto-scaling-group-name dr-app-asg \
#  --desired-capacity 0 --min-size 0 \
#  --region us-east-1

