# Flask Blog Disaster Recovery Project

## Overview

This project deploys a highly available and disaster-resilient Flask-based blog application on AWS. The application runs in a primary region (`eu-west-1`, Ireland) with a disaster recovery (DR) setup in a secondary region (`us-east-1`, N. Virginia). The architecture leverages multiple AWS services to ensure high availability, automated failover, and data consistency across regions. The project uses Terraform for infrastructure as code (IaC) to provision and manage all resources.

The primary goal is to maintain application uptime and data integrity in the event of a regional failure. The setup includes automated failover to the DR region, periodic AMI creation for instance recovery, and dynamic configuration management to minimize downtime.

## Architecture

The application is a Flask-based blog (`gideontee/flask-blog:latest`) running in Docker containers on EC2 instances. It uses an S3 bucket for static assets and an RDS MySQL database for persistent storage. The architecture is divided into primary and DR regions, with AWS Global Accelerator ensuring seamless traffic routing.

### Primary Region (eu-west-1)
- **EC2 Instances**: Managed by an Auto Scaling Group (ASG) with a minimum of 1 and a maximum of 3 instances (`t3.micro`). Instances run the Flask app in Docker, configured via a user data script.
- **Application Load Balancer (ALB)**: Distributes traffic to the ASG instances, with health checks ensuring only healthy instances receive traffic.
- **RDS MySQL**: A primary MySQL database instance (`db.t3.micro`) stores blog data.
- **S3 Bucket**: Stores static assets (e.g., images, CSS).
- **Security Groups**: Restrict traffic to HTTP (port 80) from the ALB and SSH (port 22) for management.

### DR Region (us-east-1)
- **EC2 Instances**: A DR ASG with `desired_capacity=0` (scaled to 1 during failover). Instances use AMIs copied from the primary region.
- **ALB**: Configured similarly to the primary ALB, remains inactive until failover.
- **RDS MySQL Read Replica**: A read-only replica of the primary database, promoted to primary during failover.
- **S3 Bucket**: A secondary bucket for DR, used after failover.
- **Security Groups**: Mirror the primary region’s configuration.

### Cross-Region Services
- **AWS Global Accelerator**: Routes user traffic to the healthiest ALB (primary or DR) using a static DNS name. It monitors ALB health and automatically redirects traffic during failover.
- **Systems Manager Parameter Store**: Stores dynamic configuration (S3 bucket name, RDS endpoint, latest AMI ID) for both regions.
- **CloudWatch**: Monitors ALB and RDS health, triggering failover via alarms.
- **SNS and Lambda**: Handle automated failover actions (RDS promotion, ASG scaling, configuration updates).
- **EventBridge and SSM Automation**: Schedule periodic AMI creation and copying to the DR region.

## AWS Services Used

The project leverages the following AWS services, each serving a specific role in the architecture:

1. **EC2 (Elastic Compute Cloud)**:
   - Hosts the Flask application in Docker containers.
   - Managed by Auto Scaling Groups in both regions for scalability and resilience.
   - Primary region ASG maintains 1–3 instances; DR ASG starts at 0 and scales to 1 during failover.

2. **Auto Scaling Groups (ASG)**:
   - Ensure the desired number of EC2 instances are running.
   - Use launch templates to configure instances with the Flask app, IAM roles, and user data scripts.
   - DR ASG dynamically uses the latest AMI from Parameter Store.

3. **Application Load Balancer (ALB)**:
   - Distributes incoming HTTP traffic to healthy EC2 instances.
   - Health checks (`/health` endpoint) ensure only operational instances receive traffic.
   - Deployed in both regions, with Global Accelerator routing to the active ALB.

4. **RDS (Relational Database Service)**:
   - MySQL database (`db.t3.micro`) stores blog data.
   - Primary instance in `eu-west-1`; read replica in `us-east-1`.
   - Read replica is promoted to primary during failover via Lambda.

5. **S3 (Simple Storage Service)**:
   - Stores static assets (e.g., images, stylesheets).
   - Separate buckets in `eu-west-1` and `us-east-1` for primary and DR environments.
   - EC2 instances access buckets using IAM instance profile credentials.

6. **Global Accelerator**:
   - Provides a static DNS name for the application.
   - Routes traffic to the healthiest ALB based on endpoint health checks.
   - Ensures seamless failover without DNS propagation delays.

7. **CloudWatch**:
   - Monitors primary ALB (`HealthyHostCount`) and RDS (`CPUUtilization`) health.
   - Alarms trigger SNS notifications when thresholds are breached (e.g., no healthy hosts, CPU > 80%).
   - Alarms initiate failover by invoking a Lambda function via SNS.

8. **SNS (Simple Notification Service)**:
   - Publishes CloudWatch alarm notifications to a topic (`FailoverNotifications`).
   - Triggers the failover Lambda function when alarms enter the `ALARM` state.

9. **Lambda**:
   - **Failover Lambda (`FailoverHandler`)**:
     - Promotes the DR RDS read replica to primary.
     - Scales the DR ASG to `desired_capacity=1`.
     - Updates Parameter Store with DR S3 bucket and RDS endpoint.
   - **AMI Update Lambda (`UpdateAMIParameter`)**:
     - Updates Parameter Store with the latest DR AMI ID after SSM Automation completes.

10. **Systems Manager (SSM)**:
    - **Parameter Store**:
      - Stores configuration: `/app/s3-bucket-name`, `/app/rds-endpoint`, `/app/latest-ami-id`.
      - EC2 instances fetch these at launch; Lambda updates them during failover.
    - **Automation**:
      - Runs a document (`CreateAMIFromInstance`) to create AMIs from the primary instance and copy them to `us-east-1`.
      - Triggered daily by EventBridge.

11. **EventBridge**:
    - Schedules daily AMI creation at 2 AM UTC (`cron(0 2 * * ? *)`).
    - Triggers the SSM Automation document.
    - Invokes the AMI Update Lambda when automation succeeds.

12. **IAM (Identity and Access Management)**:
    - Roles for EC2 instances (`AppInstanceRole`): Grants S3 access and SSM Parameter Store read permissions.
    - Role for Lambda (`FailoverLambdaRole`): Allows RDS promotion, ASG updates, and SSM writes.
    - Role for SSM Automation (`SSMAutomationRole`): Permits EC2 AMI creation and copying.
    - Role for AMI Update Lambda (`LambdaUpdateAMIRole`): Grants SSM and EC2 permissions.

13. **VPC (Virtual Private Cloud)**:
    - Separate VPCs in `eu-west-1` and `us-east-1` with public subnets for EC2 and ALB.
    - Security groups restrict traffic to HTTP (from ALB) and SSH.

## Project Structure

The Terraform code is organized into modules for modularity and reusability:

```
├── environments/
│   └── primary-region/
│       ├── main.tf            # Configures all modules for eu-west-1 and us-east-1
│       └── variables.tf       # Defines input variables
├── modules/
│   ├── compute/              # EC2 instances, ASGs, launch templates
│   ├── database/             # RDS primary and read replica
│   ├── dr-automation/        # CloudWatch alarms, SNS, Lambda, SSM Automation
│   ├── global/               # Global Accelerator
│   ├── iam/                  # IAM roles and policies
│   ├── load-balancing/       # ALBs for both regions
│   ├── networking/           # VPCs, subnets, security groups
│   └── storage/              # S3 buckets
└── README.md                 # This documentation
```

## Prerequisites

- **AWS Account**: Active account with permissions to create resources in `eu-west-1` and `us-east-1`.
- **Terraform**: Version 1.5 or later installed.
- **AWS CLI**: Configured with credentials (`aws configure`).
- **Docker Image**: The Flask app (`gideontee/flask-blog:latest`) must be available in a Docker registry.
- **SSH Key Pair**: An EC2 key pair for SSH access (optional, for debugging).

## Deployment Instructions

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Gideon-Tee/disaster-recovery-solution.git
   cd disaster-recovery-solution/
   ```

2. **Initialize Terraform**:
   ```bash
   cd environments/primary-region
   terraform init
   ```

3. **Configure Variables**:
   - Edit `variables.tf` or create a `terraform.tfvars` file with values for:
     - `aws_access_key`, `aws_secret_key` (optional, prefer IAM roles).
     - `s3_bucket_name`: Primary S3 bucket name.
     - `dr_ami_id`: Initial AMI ID for DR (updated by automation).
     - `key_name`: EC2 key pair name.
     - `db_username`, `db_password`, `db_name`: RDS credentials and database name.

   Example `terraform.tfvars`:
   ```hcl
    region               = "eu-west-1"
    vpc_cidr             = "12.0.0.0/16"
    public_subnet_cidrs  = ["12.0.1.0/24", "12.0.10.0/24"]
    private_subnet_cidrs = ["12.0.3.0/24", "12.0.5.0/24"]
    environment          = "primary"
    db_name              = "appDB"
    aws_secret_key       = ""
    aws_access_key       = ""
    dr_region = "us-east-1"
    account_id = ""
   ```

4. **Apply Terraform**:
   ```bash
   terraform apply
   ```
   - Review the plan and confirm with `yes`.
   - Deployment takes ~10–15 minutes to provision VPCs, EC2, RDS, ALBs, Global Accelerator, and automation resources.

5. **Access the Application**:
   - Retrieve the Global Accelerator DNS name from Terraform outputs:
     ```bash
     terraform output global_accelerator_dns_name
     ```
   - Open the DNS name in a browser to access the Flask blog.

## Disaster Recovery Workflow

### Failover to DR Region
1. **Health Monitoring**:
   - CloudWatch alarms monitor:
     - `PrimaryALBHealthyHosts`: Triggers if `HealthyHostCount < 1` for 2 minutes.
     - `PrimaryRDSCPUUtilization`: Triggers if `CPUUtilization > 80%` for 2 minutes.
   - Alarms publish to an SNS topic (`FailoverNotifications`).

2. **Failover Execution**:
   - The SNS topic invokes the `FailoverHandler` Lambda function, which:
     - Promotes the DR RDS read replica (`app-db-replica`) to primary.
     - Scales the DR ASG (`dr-app-asg`) to `desired_capacity=1`.
     - Updates Parameter Store (`/app/s3-bucket-name`, `/app/rds-endpoint`) with DR values.
   - Global Accelerator detects the primary ALB’s failure and routes traffic to the DR ALB.

3. **Verification**:
   - Check Lambda logs (`/aws/lambda/FailoverHandler`) for successful execution.
   - Verify the DR RDS instance is primary (RDS > Databases, us-east-1).
   - Confirm DR ASG has one instance (EC2 > Auto Scaling Groups, us-east-1).
   - Access the Global Accelerator DNS name to ensure the app is running from `us-east-1`.

### Recovery to Primary Region
- **Note**: Automated recovery is not yet implemented (planned for future work).
- Manual steps:
  1. Restore the primary RDS instance from a snapshot or recreate it.
  2. Reconfigure replication from the DR (now primary) to the new primary RDS.
  3. Update Parameter Store with primary S3 bucket and RDS endpoint.
  4. Scale down the DR ASG to `desired_capacity=0`.
  5. Ensure the primary ALB is healthy, allowing Global Accelerator to route traffic back.

## AMI Automation

### Overview
- An SSM Automation document (`CreateAMIFromInstance`) creates AMIs from the primary EC2 instance daily at 2 AM UTC.
- AMIs are copied to `us-east-1` and tagged (`Environment: DR`, `Name: App-AMI-<timestamp>-DR`).
- A Lambda function (`UpdateAMIParameter`) updates `/app/latest-ami-id` with the latest DR AMI ID.
- The DR ASG uses this AMI via Parameter Store.

### Verification
1. **Manual Trigger**:
   - Go to Systems Manager > Automation > `CreateAMIFromInstance` > Execute.
   - Input the primary instance ID, `SSMAutomationRole` ARN, and `us-east-1`.
2. **Check AMIs**:
   - EC2 > AMIs: Verify AMIs in `eu-west-1` (`App-AMI-<timestamp>`) and `us-east-1` (`App-AMI-<timestamp>-DR`).
3. **Check Parameter Store**:
   ```bash
   aws ssm get-parameter --name "/app/latest-ami-id" --region us-east-1
   ```
4. **Test DR ASG**:
   - Set DR ASG `desired_capacity=1` and verify the instance uses the latest AMI.

## Testing and Validation

### Failover Testing
1. Simulate a primary ALB failure:
   - EC2 > Load Balancers > Primary ALB > Edit health check > Set path to `/invalid`.
   - Wait 2 minutes for the `PrimaryALBHealthyHosts` alarm to trigger.
2. Verify failover:
   - Check Lambda logs, DR RDS, DR ASG, and Parameter Store.
   - Access the Global Accelerator DNS name to confirm DR operation.
3. Revert:
   - Restore the ALB health check path and verify traffic returns to `eu-west-1`.

### AMI Automation Testing
1. Trigger SSM Automation manually (see above).
2. Verify AMIs and Parameter Store updates.
3. Test DR ASG with the new AMI by scaling it up.

### Debugging
- **CloudWatch Logs**:
  - `/aws/lambda/FailoverHandler`: Failover errors.
  - `/aws/lambda/UpdateAMIParameter`: AMI update errors.
- **Systems Manager**:
  - Automation execution history for AMI creation issues.
- **Terraform State**:
  - Use `terraform state list` to inspect resources if errors occur.
- **IAM Permissions**:
  - Check role policies if `AccessDenied` errors appear.

## Maintenance

### Updating the Application
- Update the Docker image (`gideontee/flask-blog:latest`) in the registry.
- Terminate primary instances to trigger ASG replacement with the new image.
- Trigger AMI creation to propagate the update to `us-east-1`.

### AMI Cleanup
- AMIs accumulate daily, increasing costs.
- **Future Work**: Implement a Lambda function to deregister AMIs older than 7 days.
- Manual cleanup:
  ```bash
  aws ec2 describe-images --filters "Name=tag:Environment,Values=DR" --region us-east-1
  aws ec2 deregister-image --image-id ami-xxx --region us-east-1
  ```

### Scaling
- Adjust ASG `min_size` and `max_size` in `modules/compute/main.tf` for load changes.
- Update RDS instance types in `modules/database/main.tf` for database performance.

### Security
- Rotate `db_password` periodically and update `terraform.tfvars`.
- Restrict SSH access (port 22) to a specific CIDR block in security groups.
- Scope IAM roles to least privilege (e.g., specific S3 buckets, RDS instances).

## Known Limitations
- **Primary Region Recovery**: Not automated; requires manual steps (planned for future).
- **AMI Retention**: No automated cleanup; manual deletion needed to manage costs.
- **Data Consistency**: RDS read replica may have slight replication lag during failover.
- **Multi-Instance AMI Creation**: Assumes one primary instance; multiple instances may require refined instance selection logic.

## Future Enhancements
- **Automated Primary Recovery**: Implement Lambda to restore `eu-west-1` operation.
- **AMI Cleanup**: Add a scheduled Lambda to delete old AMIs.
- **Enhanced Monitoring**: Add CloudWatch alarms for RDS `DatabaseConnections` or `ReplicaLag`.
- **Cost Optimization**: Use Spot Instances or Savings Plans for EC2.
