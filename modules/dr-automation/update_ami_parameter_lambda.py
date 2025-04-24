import json
import boto3
import os

def handler(event, context):
    region = os.environ['REGION']
    parameter_name = os.environ['PARAMETER_NAME']

    # Initialize EC2 client
    ec2_client = boto3.client('ec2', region_name=region)

    # Fetch AMIs with tag Environment=DR, sorted by creation date
    response = ec2_client.describe_images(
        Filters=[
            {'Name': 'tag:Environment', 'Values': ['DR']},
            {'Name': 'name', 'Values': ['App-AMI-*-DR']}
        ],
        Owners=['self']
    )

    # Sort AMIs by creation date and get the latest
    amis = sorted(response['Images'], key=lambda x: x['CreationDate'], reverse=True)
    if not amis:
        return {
            'statusCode': 400,
            'body': json.dumps('No AMIs found with tag Environment=DR')
        }

    latest_ami_id = amis[0]['ImageId']

    # Update Parameter Store
    ssm_client = boto3.client('ssm', region_name=region)
    ssm_client.put_parameter(
        Name=parameter_name,
        Value=latest_ami_id,
        Type='String',
        Overwrite=True
    )

    return {
        'statusCode': 200,
        'body': json.dumps(f'Updated Parameter Store {parameter_name} with AMI ID: {latest_ami_id}')
    }