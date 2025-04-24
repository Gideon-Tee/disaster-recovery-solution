import boto3
import os
import json

def handler(event, context):
    dr_region = os.environ['DR_REGION']
    dr_rds_identifier = os.environ['DR_RDS_IDENTIFIER']
    dr_asg_name = os.environ['DR_ASG_NAME']
    dr_s3_bucket_name = os.environ['DR_S3_BUCKET_NAME']
    ssm_s3_param_name = os.environ['SSM_S3_PARAM_NAME']
    ssm_rds_param_name = os.environ['SSM_RDS_PARAM_NAME']

    # Initialize AWS clients
    rds_client = boto3.client('rds', region_name=dr_region)
    autoscaling_client = boto3.client('autoscaling', region_name=dr_region)
    ssm_client = boto3.client('ssm', region_name=dr_region)

    try:
        # Step 1: Promote RDS read replica to primary
        response = rds_client.promote_read_replica(
            DBInstanceIdentifier=dr_rds_identifier,
            BackupRetentionPeriod=1
        )
        print(f"Promoted RDS read replica {dr_rds_identifier} to primary")

        # Wait for RDS to become available
        waiter = rds_client.get_waiter('db_instance_available')
        waiter.wait(DBInstanceIdentifier=dr_rds_identifier)
        print(f"RDS instance {dr_rds_identifier} is available")

        # Get the new RDS endpoint
        response = rds_client.describe_db_instances(DBInstanceIdentifier=dr_rds_identifier)
        new_rds_endpoint = response['DBInstances'][0]['Endpoint']['Address']
        print(f"New RDS endpoint: {new_rds_endpoint}")

        # Step 2: Update DR ASG to desired_capacity = 1
        autoscaling_client.update_auto_scaling_group(
            AutoScalingGroupName=dr_asg_name,
            DesiredCapacity=1,
            MinSize=1
        )
        print(f"Updated DR ASG {dr_asg_name} to desired_capacity=1")

        # Step 3: Update SSM parameters for S3 bucket and RDS endpoint
        ssm_client.put_parameter(
            Name=ssm_s3_param_name,
            Value=dr_s3_bucket_name,
            Type='String',
            Overwrite=True
        )
        print(f"Updated SSM parameter {ssm_s3_param_name} to {dr_s3_bucket_name}")

        ssm_client.put_parameter(
            Name=ssm_rds_param_name,
            Value=new_rds_endpoint,
            Type='String',
            Overwrite=True
        )
        print(f"Updated SSM parameter {ssm_rds_param_name} to {new_rds_endpoint}")

        return {
            'statusCode': 200,
            'body': json.dumps('Failover completed successfully')
        }

    except Exception as e:
        print(f"Error during failover: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Failover failed: {str(e)}")
        }