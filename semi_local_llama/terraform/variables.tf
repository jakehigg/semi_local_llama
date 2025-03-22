variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ollama_instance_type" {
  type        = string
  default     = "m8g.medium"
  description = "The EC2 instance type for Ollama, This is a safe default.  I have also used: c8g.12xlarge"
}

variable "ollama_instance_spot_price" {
  type        = string
  default     = 0.01
  description = "The Maximum hourly price you want to pay for the instance.  Make this a little higher than the current spot price"
}

variable "ollama_instance_ami" {
  type        = string
  default     = "ami-0eae2a0fc13b15fce"
  description = "The AMI ID for Ollama, the AMI architecture must match the Instance architecture"
}

variable "ollama_volume_size" {
  type        = number
  default     = 100
  description = "The volume size for the Ollama instance"
}

variable "ollama_volume_type" {
  type        = string
  default     = "gp3"
  description = "The volume type for the Ollama instance"
}

variable "ollama_pull_model" {
  type        = string
  nullable    = true
  default     = null
  description = "An optional model to pull when the instance starts"
}
variable "ollama_instance_vpc" {
  type        = string
  default     = "vpc-deadbeef"
  description = "The VPC ID in which to launch Ollama"
}

variable "ollama_instance_subnet" {
  type        = string
  default     = "subnet-deadbeef"
  description = "The subnet ID in which to launch Ollama.  This plan builds an instance with a public ip.  I recommend using a public subnet to reduce costs"
}

variable "instance_idle_minutes" {
  type        = number
  default     = 15
  description = "This must be a multiple of 5.  The number of minutes before an instance is considered idle and stopped."
}

variable "sns_notification_arn" {
  type        = string
  nullable    = true
  default     = null
  description = "The ARN for an SNS topic to send notifications to"
}