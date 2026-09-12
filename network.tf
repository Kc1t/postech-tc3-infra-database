data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_db_subnet_group" "this" {
  name       = "${local.name}-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = local.tags

  # Em prod o subnet group foi criado antes do Terraform e importado; nome e descricao originais ficam.
  lifecycle {
    ignore_changes = [name, description]
  }
}

resource "aws_security_group" "this" {
  name        = "${local.name}-sg"
  description = "Acesso PostgreSQL ao RDS de ${var.environment}"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL a partir das faixas autorizadas"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  tags = local.tags

  # Em prod o security group foi criado antes do Terraform e importado; trocar nome ou descricao
  # recriaria o grupo com o banco preso a ele.
  lifecycle {
    ignore_changes = [name, description]
  }
}
