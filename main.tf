terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


resource "aws_vpc" "test_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "tf-test"
  }
}

resource "aws_subnet" "az_1a" {
  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tf-test-1a"
  }
}

resource "aws_subnet" "az_1b" {
  vpc_id            = aws_vpc.test_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "tf-test-1b"
  }
}

resource "aws_elasticache_subnet_group" "redis_subnet" {
  name       = "tf-test-cache-subnet"
  subnet_ids = [aws_subnet.az_1a.id, aws_subnet.az_1b.id]
}

resource "aws_elasticache_replication_group" "example_2" {
  automatic_failover_enabled  = true
  replication_group_id        = "tf-rep-group-1"
  node_type                   = "cache.t2.micro"
  number_cache_clusters       = 3
  parameter_group_name        = "default.redis6.x"
  port                        = 6379
  replication_group_description = "example"
}


resource "aws_cloudwatch_metric_alarm" "redis" {
  count = 3
  alarm_name                = "tf-rep-group-1-${format("%03d", count.index + 1)}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors redis cpu utilization"
  insufficient_data_actions = []
}

output "redis_nodes_replica" {
  value = aws_elasticache_replication_group.example_2.member_clusters
}
