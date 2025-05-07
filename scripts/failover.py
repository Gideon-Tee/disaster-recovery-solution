import boto3
import time

# Configuration
REGION = 'eu-west-1'
ASG_NAME = 'primary-app-asg'

# Initialize AWS clients
autoscaling_client = boto3.client('autoscaling', region_name=REGION)
ec2_client = boto3.client('ec2', region_name=REGION)


def get_asg_instances(asg_name):
    """Retrieve instance IDs from the specified Auto Scaling Group."""
    response = autoscaling_client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name])
    if not response['AutoScalingGroups']:
        raise Exception(f"Auto Scaling Group {asg_name} not found in region {REGION}")

    instances = response['AutoScalingGroups'][0]['Instances']
    instance_ids = [instance['InstanceId'] for instance in instances if instance['LifecycleState'] == 'InService']
    return instance_ids


def terminate_instances(instance_ids):
    """Terminate the specified EC2 instances."""
    if not instance_ids:
        print("No instances found to terminate.")
        return

    print(f"Terminating instances: {instance_ids}")
    ec2_client.terminate_instances(InstanceIds=instance_ids)

    # Wait for instances to terminate
    waiter = ec2_client.get_waiter('instance_terminated')
    waiter.wait(InstanceIds=instance_ids)
    print("Instances terminated successfully.")


def main():
    try:
        # Get instances from the ASG
        instance_ids = get_asg_instances(ASG_NAME)

        if instance_ids:
            print(f"Found {len(instance_ids)} instances in ASG {ASG_NAME}: {instance_ids}")
            terminate_instances(instance_ids)
        else:
            print(f"No running instances found in ASG {ASG_NAME}.")

        # Optional: Verify ASG desired capacity (it should attempt to replace instances)
        response = autoscaling_client.describe_auto_scaling_groups(AutoScalingGroupNames=[ASG_NAME])
        desired_capacity = response['AutoScalingGroups'][0]['DesiredCapacity']
        print(f"ASG {ASG_NAME} desired capacity: {desired_capacity}")

    except Exception as e:
        print(f"Error: {str(e)}")


if __name__ == "__main__":
    main()