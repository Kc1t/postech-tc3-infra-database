locals {
  name = "${var.project_name}-${var.environment}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "random_password" "db" {
  length  = 24
  special = false

  # A senha so muda de proposito (terraform apply -replace), nunca como efeito de mudar a configuracao.
  lifecycle {
    ignore_changes = all
  }
}

data "aws_kms_alias" "rds" {
  name = "alias/aws/rds"
}

# tfsec:ignore:aws-ssm-secret-use-customer-key O Learner Lab nao permite criar CMK; a chave gerenciada da AWS e a unica disponivel.
resource "aws_secretsmanager_secret" "db" {
  name = "${local.name}-db-credentials"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
  })
}

resource "aws_db_instance" "this" {
  identifier     = "${local.name}-postgres"
  engine         = "postgres"
  engine_version = "16"

  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  publicly_accessible    = false
  multi_az               = coalesce(var.multi_az, var.environment == "prod")
  apply_immediately      = true

  backup_retention_period = var.environment == "prod" ? 7 : 1
  skip_final_snapshot     = var.environment != "prod"

  # tfsec:ignore:aws-rds-enable-deletion-protection Ligada em prod; desligada em staging de proposito, para o terraform destroy do fim de cada sessao do lab.
  deletion_protection = var.environment == "prod"

  iam_database_authentication_enabled = true

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = data.aws_kms_alias.rds.target_key_arn
  performance_insights_retention_period = 7

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = local.tags

  # engine_version = "16" fixa a versao maior; a menor evolui pelo auto_minor_version_upgrade da AWS
  # e nao deve virar diff (nem tentativa de voltar de 16.x para "16").
  lifecycle {
    ignore_changes = [engine_version]
  }
}
