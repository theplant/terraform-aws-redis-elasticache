#
# Security group resources
#

resource "aws_sns_topic" "redis" {
  name = "${var.project}-${var.environment}"
}

resource "aws_sns_topic_subscription" "redis" {
  count = "${var.notification_webhook != "" ? 1 : 0}"
  topic_arn = "${aws_sns_topic.redis.arn}"
  protocol  = "https"
  endpoint_auto_confirms = true
  endpoint  = "${var.notification_webhook}"
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project}-${var.environment}"
  subnet_ids = ["${var.subnet_ids}"]
}

resource "aws_elasticache_parameter_group" "redis" {
  count  = "${length(var.parameter_group) != 0 ? 0 : 1}"
  name   = "${var.project}-${var.environment}"
  family = "${var.parameter_group_family}"
}

resource "aws_security_group" "redis" {
  vpc_id = "${var.vpc_id}"

  tags {
    Name        = "sgCacheCluster"
    Project     = "${var.project}"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "redis" {
  count = "${length(var.source_security_group_ids)}" 
  type = "ingress"
  from_port = 6379 
  to_port = 6379
  protocol = "tcp"
  source_security_group_id = "${element(var.source_security_group_ids, count.index)}"

  security_group_id = "${aws_security_group.redis.id}"


}

#
# ElastiCache resources
#
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "${lower(var.cache_identifier)}"
  replication_group_description = "Replication group for Redis"
  automatic_failover_enabled    = "${var.automatic_failover_enabled}"
  number_cache_clusters         = "${var.desired_clusters}"
  node_type                     = "${var.instance_type}"
  engine_version                = "${var.engine_version}"
  parameter_group_name          = "${length(var.parameter_group) != 0 ? var.parameter_group : aws_elasticache_parameter_group.redis.id}"
  subnet_group_name             = "${aws_elasticache_subnet_group.redis.name}"
  security_group_ids            = ["${aws_security_group.redis.id}"]
  maintenance_window            = "${var.maintenance_window}"
  notification_topic_arn        = "${aws_sns_topic.redis.arn}"
  port                          = "6379"

  tags {
    Name        = "CacheReplicationGroup"
    Project     = "${var.project}"
    Environment = "${var.environment}"
  }
}

#
# CloudWatch resources
#
resource "aws_cloudwatch_metric_alarm" "cache_cpu" {
  count = "${var.desired_clusters}"

  alarm_name          = "alarm${var.environment}CacheCluster00${count.index + 1}CPUUtilization"
  alarm_description   = "Redis cluster CPU utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = "300"
  statistic           = "Average"

  threshold = "${var.alarm_cpu_threshold}"

  dimensions {
    CacheClusterId = "${aws_elasticache_replication_group.redis.id}-00${count.index + 1}"
  }


  alarm_actions = ["${aws_sns_topic.redis.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "cache_memory" {
  count = "${var.desired_clusters}"

  alarm_name          = "alarm${var.environment}CacheCluster00${count.index + 1}FreeableMemory"
  alarm_description   = "Redis cluster freeable memory"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeableMemory"
  namespace           = "AWS/ElastiCache"
  period              = "60"
  statistic           = "Average"

  threshold = "${var.alarm_memory_threshold}"

  dimensions {
    CacheClusterId = "${aws_elasticache_replication_group.redis.id}-00${count.index + 1}"
  }

  alarm_actions = ["${aws_sns_topic.redis.arn}"]
}
