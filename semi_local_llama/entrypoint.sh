#!/bin/bash

# set -e
echo $TF_VAR_ollama_instance_type
echo $TF_VAR_sns_notification_arn

trap cleanup EXIT

cleanup() {
    echo "Container is shutting down, destroying Terraform resources..."
    terraform destroy -auto-approve
    sleep 5
    terraform destroy -auto-approve
    sleep 10
}

# Start Nginx to proxt the connection to SessionManager
nginx
terraform init
terraform apply -input=false -auto-approve
instance_id=$(terraform output -json | jq -r '.instance_id.value')

# Let it breathe
sleep 5

# Check if the instance is stopped, this can happen if it has been idle and shut down via CloudWatch Alarms
if [ -z "$instance_id" ]; then
  echo "Error: instance_id is not set."
  exit 1
fi

# Get the current state of the instance
state=$(aws ec2 describe-instances \
  --instance-ids "$instance_id" \
  --query "Reservations[0].Instances[0].State.Name" \
  --output text)

echo "Instance $instance_id is currently in state: $state"

# If the instance is stopped, start it
if [ "$state" = "stopped" ]; then
  echo "Starting instance $instance_id..."
  aws ec2 start-instances --instance-ids "$instance_id" > /dev/null
  echo "Start request sent."
else
  echo "No action needed."
fi

# Connect to the instance using SSM Session Manager Tunneling
max_attempts=20
attempt=1
wait_time=10  # seconds

echo "Waiting for instance $instance_id to connect to SSM..."

# Loop until successful or max attempts reached
while [ $attempt -le $max_attempts ]; do
    echo "Attempt $attempt of $max_attempts..."
    
    if aws ssm start-session --target $instance_id \
                           --document-name AWS-StartPortForwardingSession \
                           --parameters '{"portNumber":["11434"],"localPortNumber":["11434"]}'; then
        connected="true"
        break
    else
        conected="false"
        echo "Instance not yet connected. Waiting $wait_time seconds before retrying..."
        sleep $wait_time
        attempt=$((attempt+1))
    fi
done

if [[ "$connected" == "false" ]]; then
    echo "Failed to connect after $max_attempts attempts. The instance may still be initializing."
    exit 1
fi
