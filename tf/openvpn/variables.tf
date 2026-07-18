variable "region" {
  description = "AWS region"
  type = string
  default = "ap-southeast-1"
}

variable "profile" {
  description = "AWS profile"
  type = string
  default = "default"
}

variable "my_ip" {
  description = "my local external IP"
  type = string
  default = "0.0.0.0"
}
