variable "project" {
  default = "Unknown"
}

variable "environment" {
  default = "Unknown"
}

variable "vpc_id" {}

variable "cache_identifier" {}

variable "maintenance_window" {}

variable "desired_clusters" {
  default = "1"
}

variable "instance_type" {
  default = "cache.t2.micro"
}

variable "engine_version" {
  default = "3.2.4"
}

variable "automatic_failover_enabled" {
  default = false
}

variable "alarm_cpu_threshold" {
  default = "75"
}

variable "alarm_memory_threshold" {
  # 10MB
  default = "10000000"
}

variable "source_security_group_ids" {
  type = "list"
}

variable "notification_webhook" {}

variable "subnet_ids" {
  type = "list"
}

variable "parameter_group_family" { 
  default = "redis3.2"
}

variable "parameter_group" {}
