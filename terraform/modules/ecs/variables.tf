variable "private_subnets" {
  type        = list(string)
  description = "The private subnets to deploy the ECS service into"
}

variable "public_subnets" {
  type        = list(string)
  description = "The public subnets to deploy the ALB into"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID to deploy the SG into"
}
