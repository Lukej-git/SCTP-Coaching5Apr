locals {
  name_prefix = "LAC"
  tags = {
    Purpose = "CE 9 - Coaching5Apr"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"
  name    = "${local.name_prefix}-vpc"

  cidr             = "10.0.0.0/16"
  azs              = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]

  enable_nat_gateway           = false
  single_nat_gateway           = true
  enable_dns_hostnames         = true
  create_database_subnet_group = true

  tags = local.tags
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name_prefix}-rds-sg"
  description = "MySQL security group"
  vpc_id      = module.vpc.vpc_id

  # ingress
  egress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within lambda"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.tags
}

module "db" {
  source     = "terraform-aws-modules/rds/aws"
  version    = "6.10.0"
  identifier = "${local.name_prefix}-rds"
  manage_master_user_password = true

  # Supported - https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.Support.html
  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0" # DB parameter group
  major_engine_version = "8.0"      # DB option group
  instance_class       = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 22
  storage_encrypted     = false

  db_name  = "${local.name_prefix}sandboxdb"
  username = "${local.name_prefix}dbadmin"
  port     = 3306

  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.security_group.security_group_id]

  skip_final_snapshot = true
  deletion_protection = false

  tags = local.tags
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "nat_gateway_ids" {
  value = module.vpc.natgw_ids
}

# Lambda Function
resource "aws_lambda_function" "moviesdb_api" {
  function_name = "${local.name_prefix}-moviesdb-api"
  runtime       = "python3.11"  # Replace with the latest supported Python version
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_exec.arn
  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [module.security_group.security_group_id]
  }

  environment {
    variables = {
      DB_NAME     = module.db.db_instance_name
      USERNAME    = module.db.db_instance_username
      RDS_ENDPOINT = module.db.db_instance_endpoint
      DB_CREDENTIALS_SECRET_NAME = data.aws_secretsmanager_secret.cluster_secret.name
    }
  }
  
  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
}


# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_exec" {
  name = "${local.name_prefix}-moviesdb-api-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_basic_execution" {
  name       = "${local.name_prefix}-lambda-basic-execution"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Grant Lambda access to Secrets Manager
resource "aws_iam_policy" "secrets_access" {
  name = "${local.name_prefix}-secrets-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = module.db.db_instance_master_user_secret_arn
    }]
  })
}

