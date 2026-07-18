variable "region" {
  description = "AWS region"
  type = string
  default = "ap-southeast-1"
}

variable "profile" {
  description = "AWS profile"
  type = string
  default = "sky"
}

variable "v2ray_port" {
  description = "Port the v2ray/xray server listens on"
  type        = number
  default     = 42443
}

variable "v2ray_allowed_cidr" {
  description = "CIDR block allowed to connect to the v2ray/xray port"
  type        = string
  default     = "117.25.100.162/32"
}
