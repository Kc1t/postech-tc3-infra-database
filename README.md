# postech-tc3-infra-database

Provisionamento do **banco de dados gerenciado** (Amazon RDS PostgreSQL 16) do sistema de gestão de oficinas mecânicas.

Tech Challenge Fase 3 — FIAP Pós Tech SOAT.

## Propósito

Este repositório é responsável apenas pela camada de dados: instância RDS, subnet group, security group e as credenciais no Secrets Manager. O cluster Kubernetes vive em [`postech-tc3-infra-k8s`](https://github.com/Kc1t/postech-tc3-infra-k8s) e consome os outputs daqui.

## Tecnologias

- Terraform >= 1.5
- AWS: RDS PostgreSQL 16, Secrets Manager, VPC/Security Groups
- Backend de state: S3
- CI/CD: GitHub Actions com OIDC (sem chave estática)

## Arquitetura

```
                  ┌──────────────────────────────┐
                  │            VPC               │
                  │                              │
   EKS  ─────────▶│  SG :5432 ──▶ RDS PostgreSQL │
   (infra-k8s)    │                  │           │
                  └──────────────────┼───────────┘
                                     │
                            Secrets Manager
                        (user, pass, host, port)
```

## Estrutura

```
versions.tf    providers e backend
variables.tf   entradas
network.tf     subnet group + security group
main.tf        RDS, senha aleatória, secret
outputs.tf     endpoint, porta, ARN do secret
envs/          tfvars por ambiente (staging, prod)
```

## Execução local

```bash
terraform init \
  -backend-config="bucket=<seu-bucket-de-state>" \
  -backend-config="key=database/staging.tfstate" \
  -backend-config="region=us-east-1"

terraform plan  -var-file=envs/staging.tfvars
terraform apply -var-file=envs/staging.tfvars
```

Preencha o `vpc_id` real em `envs/*.tfvars` antes do primeiro apply.

## Deploy

| Evento | Ação |
|---|---|
| Pull Request | `fmt`, `validate`, `tfsec` e `plan` em staging |
| Push em `homolog` | `apply` em staging |
| Push em `main` | `apply` em produção |

Secrets necessários no repositório: `AWS_ROLE_ARN` e `TF_STATE_BUCKET`.

## Outputs

| Output | Uso |
|---|---|
| `db_address` / `db_port` | conexão da aplicação |
| `db_credentials_secret_arn` | consumido pelo app e pela lambda de autenticação |
| `db_security_group_id` | referenciado pelo `infra-k8s` para liberar o tráfego do cluster |

## Diferenças entre ambientes

| | staging | prod |
|---|---|---|
| Multi-AZ | não | sim |
| Retenção de backup | 1 dia | 7 dias |
| Deletion protection | não | sim |
| Final snapshot | pulado | obrigatório |
