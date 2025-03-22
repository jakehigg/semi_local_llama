# Semi Local Llama

Run powerful Ollama models on EC2 without needing expensive local hardware.  Keeps your data (mostly) secure.

## Overview

Semi Local Llama allows you to run large language models through Ollama on AWS EC2 instances with minimal setup. It creates a secure connection between your local machine and a high-powered EC2 instance, making it feel like you're running the model locally.  Creates a proxy available on your local network and can be used with tools like Open-WebUI and Aider.

## Features

- **On-demand powerful compute**: Access to powerful AWS EC2 instances (default: c8g.4xlarge)
- **Automatic model download**: Specify any Ollama model to be pulled automatically
- **Secure connection**: Uses AWS SSM Session Manager for secure port forwarding
- **Cost optimization**: 
  - Auto-shutdown when idle (15 minutes of low CPU usage)
  - Terraform-managed resources for clean termination

## Prerequisites

- Docker and Docker Compose installed locally
- AWS credentials configured (`~/.aws`)
- An existing VPC with public subnets in your AWS account

## Quick Start

1. Clone the repository
2. Configure your AWS environment variables in `docker-compose.yml` (see Configuration section)
3. Run the application:

```bash
docker-compose --profile ollama up --build
```

4. Access Ollama through the Open WebUI that will automatically connect to your EC2 instance at http://<host>:11435

## Configuration

Edit the `docker-compose.yml` file to configure your deployment:

```yaml
semi_local_llama:
  # ... other configuration ...
  environment:
    - TF_VAR_aws_region=us-east-1                  # AWS region to deploy to
    - TF_VAR_ollama_instance_type=c8g.4xlarge      # EC2 instance type
    - TF_VAR_ollama_instance_ami=ami-0eae2a0fc13b15fce  # AMI ID
    - TF_VAR_ollama_instance_subnet=subnet-deadbeef     # Your subnet ID
    - TF_VAR_ollama_instance_vpc=vpc-deadbeef           # Your VPC ID
    - TF_VAR_sns_notification_arn=arn:aws:sns:us-east-1:12345678:monitor-topic  # Optional SNS topic
    - TF_VAR_ollama_pull_model=qwen2.5-coder:7b         # Ollama model to pull
```

## Cleanup & Cost Management

The application includes several safeguards to prevent unexpected AWS charges:

1. **Automatic Cleanup**: Terraform resources are destroyed when the container shuts down gracefully
2. **Idle Detection**: A CloudWatch alarm stops the instance after 15 minutes of low CPU activity
3. **Manual Cleanup**: If automatic cleanup fails, run:

```bash
docker-compose --profile cleanup up
```

⚠️ **IMPORTANT**: I dont pay your bills, you do. Always confirm that your EC2 instances have been terminated. The creator of this tool is not responsible for any AWS charges you may incur.

## ToDo

- [x] Works!
- [ ] Optimize Dockerfile to support other architectures (currently ARM only)
- [ ] Add support for GPUs 
- [ ] Add support for spot pricing
- [ ] Optimize idle instance shut down
- [ ] Packer build for the instance AMI for faster launching and not downloading the Ollama models every time

## Troubleshooting

### Instance Not Terminating
Check the AWS Console and manually terminate if necessary, then run the cleanup profile.

### Connection Issues
If you're unable to connect to the instance, it may still be initializing. The application will retry several times before failing.

## How It Works

1. The container starts and runs Terraform to provision an EC2 instance
2. Ollama is installed on the instance and the specified model is pulled
3. Nginx is launched to create a reverse proxy through the tunnel
4. An SSM Session Manager connection is established for secure port forwarding
5. Local port 11435 is forwarded to the Ollama API on the EC2 instance
6. When done, Terraform destroys all resources upon container termination

## Limitations

- Only supports Ollama models
- Requires existing VPC and subnet
- Network performance depends on your connection to AWS

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.