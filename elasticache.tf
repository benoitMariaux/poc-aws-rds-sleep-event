resource "aws_elasticache_cluster" "elasticache_cluster" {
  cluster_id           = "elasticache-cluster"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2"
  engine_version       = "3.2.10"
  port                 = 6379
}

output "redis_hostname" {
  value = "${aws_elasticache_cluster.elasticache_cluster.cache_nodes.0.address}"
}

output "redis_port" {
  value = "${aws_elasticache_cluster.elasticache_cluster.cache_nodes.0.port}"
}

output "redis_endpoint" {
  value = "${aws_elasticache_cluster.elasticache_cluster.cache_nodes.0.address}"
}

# An instance in the default VPC in order to access to the Redis cluster
resource "aws_instance" "accessing_redis" {
  ami           = "ami-089950bc622d39ed8"
  instance_type = "t3.micro"

  tags = {
    Name = "for Redis only"
  }

  user_data = <<EOF
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

yum update -y
amazon-linux-extras install redis6

git clone git@github.com:benoitMariaux/poc-aws-rds-sleep-event.git 

redis-cli -h ${aws_elasticache_cluster.elasticache_cluster.cache_nodes.0.address} -p 6379 < poc-aws-rds-sleep-event/movies.redis
EOF
}