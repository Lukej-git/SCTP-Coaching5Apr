data "aws_availability_zones" "available" {
  state = "available"
}

# Retrieve Secret Values from AWS Secrets Manager
# data "aws_secretsmanager_secret" "cluster_secret" {
#   arn = module.db.db_instance_master_user_secret_arn
# }